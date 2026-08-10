use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::{event_instance_sync_destinations, event_sync_destinations};

pub fn delete_event_sync_destination(
    request: DeleteEventSyncDestinationRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let requested_destination = request
        .destination
        .ok_or(Status::new(Code::InvalidArgument, "destination_required"))?;
    let destination_id = requested_destination.id.to_db_id_or_err("destination.id")?;
    let existing = models::get_event_sync_destination(destination_id, conn)?;

    if existing.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    // `delete_synced_posts` is intentionally a no-op today: deleting the already-posted Facebook
    // content would require the Page's access token to remain valid at delete time and isn't
    // implemented yet. Disconnecting always stops future syncing; it just leaves existing posts
    // up on Facebook.
    let _ = request.delete_synced_posts;

    diesel::delete(
        event_instance_sync_destinations::table
            .filter(event_instance_sync_destinations::event_sync_destination_id.eq(existing.id)),
    )
    .execute(conn)
    .map_err(|e| {
        log::error!(
            "Failed to delete sync statuses for destination {}: {:?}",
            existing.id,
            e
        );
        Status::new(Code::Internal, "failed_to_delete_event_sync_destination")
    })?;

    diesel::delete(event_sync_destinations::table.filter(event_sync_destinations::id.eq(existing.id)))
        .execute(conn)
        .map_err(|e| {
            log::error!(
                "Failed to delete event sync destination {}: {:?}",
                existing.id,
                e
            );
            Status::new(Code::Internal, "failed_to_delete_event_sync_destination")
        })?;

    Ok(())
}
