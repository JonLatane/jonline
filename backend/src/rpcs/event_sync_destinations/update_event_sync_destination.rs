use std::time::SystemTime;

use diesel::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::connect_facebook_page;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::event_sync_destinations;

/// Only used to reconnect (re-run the OAuth exchange for) an existing destination -- e.g. after
/// the user revoked/re-granted Facebook access. `page_id` can't be changed this way; delete and
/// create a new destination instead.
pub fn update_event_sync_destination(
    request: EventSyncDestination,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<EventSyncDestination, Status> {
    validate_permission(&Some(current_user), Permission::SyncEventsToFacebook)?;

    let destination_id = request.id.to_db_id_or_err("id")?;
    let mut existing = models::get_event_sync_destination(destination_id, conn)?;

    if existing.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    if let Some(event_sync_destination::Configuration::FacebookPage(FacebookPage {
        short_lived_user_access_token: Some(short_lived_user_access_token),
        ..
    })) = request.configuration
    {
        let existing_page_id = existing
            .configuration
            .get("facebook_page")
            .and_then(|c| c.get("page_id"))
            .and_then(|v| v.as_str())
            .ok_or_else(|| {
                Status::new(
                    Code::FailedPrecondition,
                    "event_sync_destination_not_configured",
                )
            })?
            .to_string();
        let connection = connect_facebook_page(&short_lived_user_access_token, &existing_page_id)?;
        existing.configuration = json!({
            "facebook_page": {
                "page_id": connection.page_id,
                "page_name": connection.page_name,
                "access_token": connection.access_token,
            }
        });
    }
    existing.updated_at = Some(SystemTime::now());

    let updated = diesel::update(
        event_sync_destinations::table.filter(event_sync_destinations::id.eq(existing.id)),
    )
    .set(&existing)
    .get_result::<models::EventSyncDestination>(conn)
    .map_err(|e| {
        log::error!("Failed to update event sync destination: {:?}", e);
        Status::new(Code::Internal, "failed_to_update_event_sync_destination")
    })?;

    let owner = models::get_author(updated.user_id, conn)?;
    Ok(MarshalableEventSyncDestination(updated, owner).to_proto())
}
