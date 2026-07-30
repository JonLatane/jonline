use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;

pub fn get_event_sync_sources(
    request: User,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<GetEventSyncSourcesResponse, Status> {
    let target_user_id = if request.id.trim().is_empty() {
        current_user.id
    } else {
        request.id.to_db_id_or_err("id")?
    };

    if target_user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    let sources = models::get_event_sync_sources_for_user(target_user_id, conn)?;
    Ok(GetEventSyncSourcesResponse {
        sources: sources
            .into_iter()
            .map(|(source, owner)| MarshalableEventSyncSource(source, owner).to_proto())
            .collect(),
    })
}
