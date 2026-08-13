use std::time::SystemTime;

use chrono::{DateTime, Utc};
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{post_event_instance, EventInstancePost};
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
    validate_permission(&Some(current_user), Permission::SyncEventsToFacebook)?;

    let instance_id = request
        .event_instance_id
        .to_db_id_or_err("event_instance_id")?;
    let destination_id = request
        .event_sync_destination_id
        .to_db_id_or_err("event_sync_destination_id")?;

    let instance = models::get_event_instance(instance_id, &Some(current_user), conn)?;
    let post: models::Post = posts::table
        .select(POST_COLUMNS)
        .filter(posts::id.eq(instance.post_id))
        .first(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_instance_post_not_found"))?;

    let destination = models::get_event_sync_destination(destination_id, conn)?;
    if destination.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

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

    // Only buildable when this server has `external_cdn_config.frontend_host` configured -- this
    // RPC has no HTTP `Host` header to fall back on the way web-facing routes
    // (`configured_frontend_domain`) do, so the link is simply omitted otherwise. See
    // `docs/facebook_federation.md`.
    let frontend_host = get_server_configuration_proto(conn)?
        .external_cdn_config
        .map(|c| c.frontend_host)
        .filter(|h| !h.trim().is_empty());
    let event_url =
        frontend_host.map(|host| format!("https://{host}/event/{}", instance.id.to_proto_id()));

    let (destination_instance_id, destination_url) = post_event_instance(
        &destination,
        &EventInstancePost {
            title: &post.title,
            content: &post.content,
            link: &post.link,
            starts_at,
            ends_at,
            location: &location,
            timezone,
            event_url: &event_url,
        },
    )?;

    let new_row = models::NewEventInstanceSyncDestination {
        event_instance_id: instance.id,
        event_sync_destination_id: destination.id,
        destination_instance_id: Some(destination_instance_id),
        destination_url: Some(destination_url),
        synced_at: Some(SystemTime::now()),
    };
    insert_into(event_instance_sync_destinations::table)
        .values(&new_row)
        .on_conflict((
            event_instance_sync_destinations::event_instance_id,
            event_instance_sync_destinations::event_sync_destination_id,
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
