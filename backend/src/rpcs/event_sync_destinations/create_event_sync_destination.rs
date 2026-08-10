use diesel::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{connect_facebook_page, server_facebook_app_credentials};
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::event_sync_destinations;

pub fn create_event_sync_destination(
    request: EventSyncDestination,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<EventSyncDestination, Status> {
    // Create is always for the current user -- admins may manage other users' destinations (see
    // `update_event_sync_destination`/`delete_event_sync_destination`) but never create one on
    // their behalf.
    //
    // Gated by `SYNC_EVENTS_TO_FACEBOOK` rather than the broader `SYNCHRONIZE_EVENTS` (used by
    // `EventSyncSource`) since posting to a third-party Facebook Page is a more sensitive grant
    // than pulling events in from one. Every `EventSyncDestination` today is a `FacebookPage`, so
    // this is unconditional; a future non-Facebook destination type would need its own check.
    validate_permission(&Some(current_user), Permission::SyncEventsToFacebook)?;

    let configuration = match request.configuration {
        Some(event_sync_destination::Configuration::FacebookPage(FacebookPage {
            page_id,
            short_lived_user_access_token: Some(short_lived_user_access_token),
            ..
        })) if !page_id.trim().is_empty() && !short_lived_user_access_token.trim().is_empty() => {
            let (app_id, app_secret) = server_facebook_app_credentials(conn)?;
            let connection = connect_facebook_page(
                &app_id,
                &app_secret,
                &short_lived_user_access_token,
                &page_id,
            )?;
            json!({
                "facebook_page": {
                    "page_id": connection.page_id,
                    "page_name": connection.page_name,
                    "access_token": connection.access_token,
                }
            })
        }
        _ => {
            return Err(Status::new(
                Code::InvalidArgument,
                "facebook_page.page_id_and_short_lived_user_access_token_required",
            ))
        }
    };

    let inserted = insert_into(event_sync_destinations::table)
        .values(&models::NewEventSyncDestination {
            user_id: current_user.id,
            configuration,
        })
        .get_result::<models::EventSyncDestination>(conn)
        .map_err(|e| {
            log::error!("Failed to create event sync destination: {:?}", e);
            Status::new(Code::Internal, "failed_to_create_event_sync_destination")
        })?;

    Ok(MarshalableEventSyncDestination(inserted, current_user.to_author()).to_proto())
}
