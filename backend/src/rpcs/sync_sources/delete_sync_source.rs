use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::{events, sync_sources};

pub fn delete_sync_source(
    request: DeleteSyncSourceRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let requested_source = request
        .source
        .ok_or(Status::new(Code::InvalidArgument, "source_required"))?;
    let source_id = requested_source.id.to_db_id_or_err("source.id")?;
    let existing = models::get_sync_source(source_id, conn)?;

    if existing.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    if request.delete_synced_events {
        diesel::delete(events::table.filter(events::sync_source_id.eq(existing.id)))
            .execute(conn)
            .map_err(|e| {
                log::error!(
                    "Failed to delete events synced from source {}: {:?}",
                    existing.id,
                    e
                );
                Status::new(Code::Internal, "failed_to_delete_synced_events")
            })?;
    } else {
        diesel::update(events::table.filter(events::sync_source_id.eq(existing.id)))
            .set(events::sync_source_id.eq(None::<i64>))
            .execute(conn)
            .map_err(|e| {
                log::error!(
                    "Failed to detach events synced from source {}: {:?}",
                    existing.id,
                    e
                );
                Status::new(Code::Internal, "failed_to_detach_synced_events")
            })?;
    }

    diesel::delete(sync_sources::table.filter(sync_sources::id.eq(existing.id)))
        .execute(conn)
        .map_err(|e| {
            log::error!("Failed to delete sync source {}: {:?}", existing.id, e);
            Status::new(Code::Internal, "failed_to_delete_sync_source")
        })?;

    Ok(())
}
