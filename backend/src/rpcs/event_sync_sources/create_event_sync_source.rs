use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::sync_event_sync_source;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::event_sync_sources;

const DEFAULT_SYNC_INTERVAL_SECONDS: i64 = 3600;
const MIN_SYNC_INTERVAL_SECONDS: i64 = 60;

pub fn create_event_sync_source(
    request: EventSyncSource,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<EventSyncSource, Status> {
    // Create is always for the current user -- admins may manage other users' sources (see
    // `update_event_sync_source`/`delete_event_sync_source`) but never create one on their
    // behalf.
    validate_permission(&Some(current_user), Permission::SynchronizeEvents)?;

    let configuration = configuration_to_json(&request.configuration);
    if configuration
        .get("ics_subscription_url")
        .and_then(|v| v.as_str())
        .map(|s| s.trim().is_empty())
        .unwrap_or(true)
    {
        return Err(Status::new(Code::InvalidArgument, "ics_subscription_url_required"));
    }

    let sync_interval_seconds = if request.sync_interval_seconds == 0 {
        DEFAULT_SYNC_INTERVAL_SECONDS
    } else if (request.sync_interval_seconds as i64) < MIN_SYNC_INTERVAL_SECONDS {
        return Err(Status::new(Code::InvalidArgument, "sync_interval_seconds_too_short"));
    } else {
        request.sync_interval_seconds as i64
    };

    let inserted = insert_into(event_sync_sources::table)
        .values(&models::NewEventSyncSource {
            user_id: current_user.id,
            sync_interval_seconds,
            configuration,
        })
        .get_result::<models::EventSyncSource>(conn)
        .map_err(|e| {
            log::error!("Failed to create event sync source: {:?}", e);
            Status::new(Code::Internal, "failed_to_create_event_sync_source")
        })?;

    // Not transactional with the insert above (per product decision) -- if the very first sync
    // fails, delete the source we just created rather than leaving a never-synced, broken row
    // around, and surface the sync error to the caller.
    if let Err(sync_err) = sync_event_sync_source(&inserted, conn) {
        log::error!(
            "Initial sync failed for new EventSyncSource {}, deleting it: {:?}",
            inserted.id,
            sync_err
        );
        if let Err(e) = diesel::delete(event_sync_sources::table.filter(event_sync_sources::id.eq(inserted.id)))
            .execute(conn)
        {
            log::error!(
                "Failed to delete EventSyncSource {} after failed initial sync: {:?}",
                inserted.id,
                e
            );
        }
        return Err(sync_err);
    }

    let synced = models::get_event_sync_source(inserted.id, conn)?;
    Ok(MarshalableEventSyncSource(synced, current_user.to_author()).to_proto())
}
