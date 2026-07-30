use std::time::SystemTime;

use diesel::*;
use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::logic::sync_event_sync_source;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::event_sync_sources;

pub fn update_event_sync_source(
    request: EventSyncSource,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<EventSyncSource, Status> {
    validate_permission(&Some(current_user), Permission::SynchronizeEvents)?;

    let source_id = request.id.to_db_id_or_err("id")?;
    let mut existing = models::get_event_sync_source(source_id, conn)?;

    if existing.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    if request.sync_interval_seconds > 0 {
        existing.sync_interval_seconds = request.sync_interval_seconds as i64;
    }
    if request.configuration.is_some() {
        existing.configuration = configuration_to_json(&request.configuration);
    }
    existing.updated_at = Some(SystemTime::now());

    let mut existing = diesel::update(event_sync_sources::table.filter(event_sync_sources::id.eq(existing.id)))
        .set(&existing)
        .get_result::<models::EventSyncSource>(conn)
        .map_err(|e| {
            log::error!("Failed to update event sync source: {:?}", e);
            tonic::Status::new(tonic::Code::Internal, "failed_to_update_event_sync_source")
        })?;

    let owner = models::get_author(existing.user_id, conn)?;

    // Unlike create, a failed re-sync doesn't undo the config change -- the caller (and the UI's
    // "last synced at") can see the source still exists but didn't sync just now.
    sync_event_sync_source(&existing, conn)?;
    existing = models::get_event_sync_source(existing.id, conn)?;

    Ok(MarshalableEventSyncSource(existing, owner).to_proto())
}
