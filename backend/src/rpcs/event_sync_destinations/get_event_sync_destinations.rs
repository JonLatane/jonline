use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;

pub fn get_event_sync_destinations(
    request: User,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<GetEventSyncDestinationsResponse, Status> {
    let target_user_id = if request.id.trim().is_empty() {
        current_user.id
    } else {
        request.id.to_db_id_or_err("id")?
    };

    if target_user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    let destinations = models::get_event_sync_destinations_for_user(target_user_id, conn)?;
    Ok(GetEventSyncDestinationsResponse {
        destinations: destinations
            .into_iter()
            .map(|(destination, owner)| MarshalableEventSyncDestination(destination, owner).to_proto())
            .collect(),
    })
}
