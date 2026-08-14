use diesel::*;
use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::event_instance_sync_destinations;

pub fn delete_event_instance_sync_destination(
    request: DeleteEventInstanceSyncDestinationRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    validate_permission(&Some(current_user), Permission::SyncEventsToFacebook)?;

    let instance_id = request
        .event_instance_id
        .to_db_id_or_err("event_instance_id")?;
    let destination_id = request
        .event_sync_destination_id
        .to_db_id_or_err("event_sync_destination_id")?;

    let destination = models::get_event_sync_destination(destination_id, conn)?;
    if destination.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    diesel::delete(
        event_instance_sync_destinations::table.filter(
            event_instance_sync_destinations::event_instance_id
                .eq(instance_id)
                .and(event_instance_sync_destinations::event_sync_destination_id.eq(destination.id)),
        ),
    )
    .execute(conn)
    .map_err(|e| {
        log::error!(
            "Failed to delete event instance sync destination ({}, {}): {:?}",
            instance_id,
            destination.id,
            e
        );
        Status::new(
            tonic::Code::Internal,
            "failed_to_delete_event_instance_sync_destination",
        )
    })?;

    Ok(())
}
