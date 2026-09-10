use std::time::SystemTime;

use chrono::{DateTime, Utc};
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{
    build_event_instance_message, post_event_instance, post_record, post_status, post_thread,
    post_to_instagram, post_tweet, EventInstanceMessageInput, MediaAttachment,
};
use crate::marshaling::*;
use crate::models;
use crate::models::POST_COLUMNS;
use crate::protos::*;
use crate::rpcs::{get_server_configuration_proto, validate_permission};
use crate::schema::{event_instance_sync_destinations, posts};

pub fn sync_event_instance(
    request: SyncEventInstanceRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<EventInstance, Status> {
    let instance_id = request
        .event_instance_id
        .to_db_id_or_err("event_instance_id")?;
    let destination_id = request
        .sync_destination_id
        .to_db_id_or_err("sync_destination_id")?;

    let instance = models::get_event_instance(instance_id, &Some(current_user), conn)?;
    let instance_post: models::Post = posts::table
        .select(POST_COLUMNS)
        .filter(posts::id.eq(instance.post_id))
        .first(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_instance_post_not_found"))?;
    let event = models::get_event(instance.event_id, &Some(current_user), conn)?;
    let event_post: models::Post = posts::table
        .select(POST_COLUMNS)
        .filter(posts::id.eq(event.post_id))
        .first(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_post_not_found"))?;

    let destination = models::get_sync_destination(destination_id, conn)?;
    if destination.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    // Gated per the destination's actual platform (`SYNC_EVENTS_TO_*`) rather than the single
    // `SyncEventsToFacebook` this used to hardcode -- see `sync_destination::Configuration`.
    let configuration = destination_configuration_to_proto(&destination.configuration);
    match &configuration {
        Some(sync_destination::Configuration::FacebookPage(_)) => {
            validate_permission(&Some(current_user), Permission::SyncEventsToFacebook)?
        }
        Some(sync_destination::Configuration::InstagramAccount(_)) => {
            validate_permission(&Some(current_user), Permission::SyncEventsToInstagram)?
        }
        Some(sync_destination::Configuration::MastodonAccount(_)) => {
            validate_permission(&Some(current_user), Permission::SyncEventsToMastodon)?
        }
        Some(sync_destination::Configuration::BlueskyAccount(_)) => {
            validate_permission(&Some(current_user), Permission::SyncEventsToBluesky)?
        }
        Some(sync_destination::Configuration::XTwitterAccount(_)) => {
            validate_permission(&Some(current_user), Permission::SyncEventsToXTwitter)?
        }
        Some(sync_destination::Configuration::ThreadsAccount(_)) => {
            validate_permission(&Some(current_user), Permission::SyncEventsToThreads)?
        }
        None => {
            return Err(Status::new(
                Code::FailedPrecondition,
                "sync_destination_not_configured",
            ))
        }
    };

    let starts_at: DateTime<Utc> = instance.starts_at.into();
    let ends_at: DateTime<Utc> = instance.ends_at.into();
    let location = instance
        .location
        .as_ref()
        .and_then(|l| l.get("uniformly_formatted_address"))
        .and_then(|v| v.as_str())
        .filter(|a| !a.trim().is_empty())
        .map(str::to_string);
    // Prefer the instance's own DB-set `timezone` (set by hand via `CreateNewPanel`/`EventPage`'s
    // timezone selector, or from an ICS Sync Source's own `DTSTART` `TZID`) over geocoding the
    // location through Nominatim -- that's a best-effort fallback for instances with no explicit
    // timezone at all (see `logic::resolve_timezone`'s own doc).
    let timezone = instance
        .timezone
        .as_deref()
        .and_then(|tz| tz.parse::<chrono_tz::Tz>().ok())
        .or_else(|| location.as_deref().and_then(crate::logic::resolve_timezone));

    // Only buildable when this server has `external_cdn_config.frontend_host`/`backend_host`
    // configured -- this RPC has no HTTP `Host` header to fall back on the way web-facing routes
    // (`configured_frontend_domain`) do, so both are simply omitted otherwise. See
    // `docs/facebook_and_x_twitter_federation.md`.
    let external_cdn_config = get_server_configuration_proto(conn)?.external_cdn_config;
    let event_url = external_cdn_config
        .as_ref()
        .map(|c| c.frontend_host.clone())
        .filter(|h| !h.trim().is_empty())
        .map(|host| format!("https://{host}/event/{}", instance.post_id.to_proto_id()));
    let media_ids: Vec<i64> = combine_media(&event_post.media, &instance_post.media);
    let media_lookup = load_media_lookup(media_ids.clone(), conn);
    let media: Vec<MediaAttachment> = external_cdn_config
        .as_ref()
        .map(|c| c.backend_host.clone())
        .filter(|h| !h.trim().is_empty())
        .map(|host| {
            media_ids
                .iter()
                .map(|id| MediaAttachment {
                    url: format!("https://{host}/media/{}", id.to_proto_id()),
                    content_type: media_lookup
                        .as_ref()
                        .find_media(*id)
                        .map(|m| m.content_type.clone())
                        .unwrap_or_default(),
                })
                .collect()
        })
        .unwrap_or_default();

    // The instance's own Post carries only a per-instance *override* of the parent Event's own
    // title/content (often unset, e.g. a plain weekly recurrence with nothing instance-specific to
    // say) -- so the synced message always leads with the Event's own title/content, appending the
    // instance's as a distinguishing suffix only when it actually set one. See
    // `combine_title`/`combine_content`'s own docs for the exact formats.
    let title = combine_title(&event_post.title, &instance_post.title);
    let content = combine_content(&event_post.content, &instance_post.content);

    let message = build_event_instance_message(EventInstanceMessageInput {
        title: &title,
        content: &content,
        link: &instance_post.link,
        starts_at,
        ends_at,
        location: &location,
        timezone,
        event_url: &event_url,
        media,
    });

    let (destination_instance_id, destination_url) = match &configuration {
        Some(sync_destination::Configuration::FacebookPage(_)) => {
            post_event_instance(&destination, &message)?
        }
        Some(sync_destination::Configuration::InstagramAccount(_)) => {
            post_to_instagram(&destination, &message)?
        }
        Some(sync_destination::Configuration::MastodonAccount(_)) => {
            post_status(&destination, &message)?
        }
        Some(sync_destination::Configuration::BlueskyAccount(_)) => {
            post_record(&destination, &message)?
        }
        Some(sync_destination::Configuration::XTwitterAccount(_)) => {
            post_tweet(&destination, &message, conn)?
        }
        Some(sync_destination::Configuration::ThreadsAccount(_)) => {
            post_thread(&destination, &message)?
        }
        None => {
            return Err(Status::new(
                Code::FailedPrecondition,
                "sync_destination_not_configured",
            ))
        }
    };

    let new_row = models::NewEventInstanceSyncDestination {
        event_instance_id: instance.post_id,
        sync_destination_id: destination.id,
        destination_instance_id: Some(destination_instance_id),
        destination_url: Some(destination_url),
        synced_at: Some(SystemTime::now()),
    };
    insert_into(event_instance_sync_destinations::table)
        .values(&new_row)
        .on_conflict((
            event_instance_sync_destinations::event_instance_id,
            event_instance_sync_destinations::sync_destination_id,
        ))
        .do_update()
        .set(&new_row)
        .execute(conn)
        .map_err(|e| {
            log::error!("Failed to record event instance sync status: {:?}", e);
            Status::new(Code::Internal, "failed_to_record_event_instance_sync")
        })?;

    let instance_post_id = instance.post_id.to_proto_id();
    let events = crate::rpcs::get_events(
        GetEventsRequest {
            post_id: Some(instance_post_id.clone()),
            ..Default::default()
        },
        &Some(current_user),
        conn,
    )?
    .events;
    events
        .into_iter()
        .find_map(|event| {
            event.instances.into_iter().find(|i| {
                i.post.as_ref().map(|p| p.id.as_str()) == Some(instance_post_id.as_str())
            })
        })
        .ok_or_else(|| Status::new(Code::Internal, "failed_to_reload_synced_event_instance"))
}

/// `"{event_title}: {instance_title}"` when `instance_title` is set (non-empty), else just
/// `event_title` alone -- e.g. "Run Club" or "Run Club: Special Holiday Edition". Falls back to
/// `instance_title` alone in the (unusual) case `event_title` itself is unset.
fn combine_title(event_title: &Option<String>, instance_title: &Option<String>) -> Option<String> {
    combine(event_title, instance_title, ": ")
}

/// `"{event_content}\n\n---\n\n{instance_content}"` when `instance_content` is set (non-empty),
/// else just `event_content` alone. Falls back to `instance_content` alone in the (unusual) case
/// `event_content` itself is unset.
fn combine_content(event_content: &Option<String>, instance_content: &Option<String>) -> Option<String> {
    combine(event_content, instance_content, "\n\n---\n\n")
}

/// Unions the Event's own Post's media with the EventInstance's own Post's media, Event-first --
/// an instance-level Post rarely carries its own media override (e.g. a plain weekly recurrence
/// with nothing instance-specific to show), so without this an Event's actual photos/video
/// (attached to the *Event's* Post, not any particular instance) would never get synced at all.
/// Mirrors `combine_title`/`combine_content`'s Event+instance merge, just as a set union instead
/// of a text join since there's no natural primary/secondary ordering for media the way there is
/// for title/content.
fn combine_media(event_media: &[Option<i64>], instance_media: &[Option<i64>]) -> Vec<i64> {
    let mut ids: Vec<i64> = event_media.iter().filter_map(|m| *m).collect();
    for id in instance_media.iter().filter_map(|m| *m) {
        if !ids.contains(&id) {
            ids.push(id);
        }
    }
    ids
}

fn combine(primary: &Option<String>, secondary: &Option<String>, separator: &str) -> Option<String> {
    let primary = primary.as_deref().map(str::trim).filter(|s| !s.is_empty());
    let secondary = secondary.as_deref().map(str::trim).filter(|s| !s.is_empty());
    match (primary, secondary) {
        (Some(p), Some(s)) => Some(format!("{p}{separator}{s}")),
        (Some(p), None) => Some(p.to_string()),
        (None, Some(s)) => Some(s.to_string()),
        (None, None) => None,
    }
}
