use std::time::SystemTime;

use chrono::{DateTime, Utc};
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{
    build_event_instance_message, post_event_instance, post_record, post_status, post_thread,
    post_to_instagram, EventInstanceMessageInput, MediaAttachment,
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
    let post: models::Post = posts::table
        .select(POST_COLUMNS)
        .filter(posts::id.eq(instance.post_id))
        .first(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_instance_post_not_found"))?;

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
    let timezone = location.as_deref().and_then(crate::logic::resolve_timezone);

    // Only buildable when this server has `external_cdn_config.frontend_host`/`backend_host`
    // configured -- this RPC has no HTTP `Host` header to fall back on the way web-facing routes
    // (`configured_frontend_domain`) do, so both are simply omitted otherwise. See
    // `docs/facebook_and_x_twitter_federation.md`.
    let external_cdn_config = get_server_configuration_proto(conn)?.external_cdn_config;
    let event_url = external_cdn_config
        .as_ref()
        .map(|c| c.frontend_host.clone())
        .filter(|h| !h.trim().is_empty())
        .map(|host| format!("https://{host}/event/{}", instance.id.to_proto_id()));
    let media_ids: Vec<i64> = post.media.iter().filter_map(|m| *m).collect();
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

    let message = build_event_instance_message(EventInstanceMessageInput {
        title: &post.title,
        content: &post.content,
        link: &post.link,
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
            return Err(Status::new(Code::FailedPrecondition, "x_twitter_app_not_configured"))
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
        event_instance_id: instance.id,
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

    let events = crate::rpcs::get_events(
        GetEventsRequest {
            event_instance_id: Some(instance.id.to_proto_id()),
            ..Default::default()
        },
        &Some(current_user),
        conn,
    )?
    .events;
    events
        .into_iter()
        .find_map(|event| {
            event
                .instances
                .into_iter()
                .find(|i| i.id == instance.id.to_proto_id())
        })
        .ok_or_else(|| Status::new(Code::Internal, "failed_to_reload_synced_event_instance"))
}
