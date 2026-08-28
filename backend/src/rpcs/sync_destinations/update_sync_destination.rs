use std::time::SystemTime;

use diesel::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{
    connect_facebook_page, create_session, get_linked_instagram_business_account,
    server_facebook_app_credentials, verify_credentials,
};
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::{validate_any_permission, validate_permission};
use crate::schema::sync_destinations;

/// Only used to reconnect (re-run the credential check for) an existing destination -- e.g. after
/// the user revoked/re-granted Facebook access, or rotated a Mastodon/Bluesky credential.
/// Facebook/Instagram's `page_id` can't be changed this way (Mastodon's `instance_host`/Bluesky's
/// `handle` must also match the existing row -- see each arm below); delete and create a new
/// destination instead to actually switch accounts.
pub fn update_sync_destination(
    request: SyncDestination,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<SyncDestination, Status> {
    // Gated per-platform, same as `create_sync_destination` -- see its own comment on this match's
    // shape (permission checked before configuration completeness, `None` falling back to the
    // Facebook pair to preserve this RPC's original behavior).
    match &request.configuration {
        Some(sync_destination::Configuration::FacebookPage(_)) | None => validate_any_permission(
            &Some(current_user),
            vec![
                Permission::SyncEventsToFacebook,
                Permission::SyncPostsToFacebook,
                Permission::Admin,
            ],
        )?,
        Some(sync_destination::Configuration::InstagramAccount(_)) => validate_any_permission(
            &Some(current_user),
            vec![
                Permission::SyncEventsToInstagram,
                Permission::SyncPostsToInstagram,
                Permission::Admin,
            ],
        )?,
        Some(sync_destination::Configuration::MastodonAccount(_)) => validate_any_permission(
            &Some(current_user),
            vec![
                Permission::SyncEventsToMastodon,
                Permission::SyncPostsToMastodon,
                Permission::Admin,
            ],
        )?,
        Some(sync_destination::Configuration::BlueskyAccount(_)) => validate_any_permission(
            &Some(current_user),
            vec![
                Permission::SyncEventsToBluesky,
                Permission::SyncPostsToBluesky,
                Permission::Admin,
            ],
        )?,
        Some(sync_destination::Configuration::XTwitterAccount(_)) => {}
    };

    let destination_id = request.id.to_db_id_or_err("id")?;
    let mut existing = models::get_sync_destination(destination_id, conn)?;

    if existing.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    let not_configured =
        || Status::new(Code::FailedPrecondition, "sync_destination_not_configured");

    match request.configuration {
        Some(sync_destination::Configuration::FacebookPage(FacebookPage {
            short_lived_user_access_token: Some(short_lived_user_access_token),
            ..
        })) => {
            let existing_page_id = existing
                .configuration
                .get("facebook_page")
                .and_then(|c| c.get("page_id"))
                .and_then(|v| v.as_str())
                .ok_or_else(not_configured)?
                .to_string();
            let (app_id, app_secret) = server_facebook_app_credentials(conn)?;
            let connection = connect_facebook_page(
                &app_id,
                &app_secret,
                &short_lived_user_access_token,
                &existing_page_id,
            )?;
            existing.configuration = json!({
                "facebook_page": {
                    "page_id": connection.page_id,
                    "page_name": connection.page_name,
                    "access_token": connection.access_token,
                }
            });
        }
        Some(sync_destination::Configuration::InstagramAccount(InstagramAccount {
            short_lived_user_access_token: Some(short_lived_user_access_token),
            ..
        })) => {
            let existing_page_id = existing
                .configuration
                .get("instagram_account")
                .and_then(|c| c.get("page_id"))
                .and_then(|v| v.as_str())
                .ok_or_else(not_configured)?
                .to_string();
            let (app_id, app_secret) = server_facebook_app_credentials(conn)?;
            let connection = connect_facebook_page(
                &app_id,
                &app_secret,
                &short_lived_user_access_token,
                &existing_page_id,
            )?;
            let (instagram_business_account_id, username) = get_linked_instagram_business_account(
                &connection.access_token,
                &connection.page_id,
            )?;
            existing.configuration = json!({
                "instagram_account": {
                    "instagram_business_account_id": instagram_business_account_id,
                    "username": username,
                    "page_id": connection.page_id,
                    "access_token": connection.access_token,
                }
            });
        }
        Some(sync_destination::Configuration::MastodonAccount(MastodonAccount {
            instance_host,
            access_token: Some(access_token),
            ..
        })) if !instance_host.trim().is_empty() && !access_token.trim().is_empty() => {
            let username = verify_credentials(&instance_host, &access_token)?;
            existing.configuration = json!({
                "mastodon_account": {
                    "instance_host": instance_host,
                    "username": username,
                    "access_token": access_token,
                }
            });
        }
        Some(sync_destination::Configuration::BlueskyAccount(BlueskyAccount {
            handle,
            app_password: Some(app_password),
            ..
        })) if !handle.trim().is_empty() && !app_password.trim().is_empty() => {
            let (did, _access_jwt) = create_session(&handle, &app_password)?;
            existing.configuration = json!({
                "bluesky_account": {
                    "handle": handle,
                    "did": did,
                    "app_password": app_password,
                }
            });
        }
        Some(sync_destination::Configuration::XTwitterAccount(_)) => {
            return Err(Status::new(Code::FailedPrecondition, "x_twitter_app_not_configured"))
        }
        // No new credential given -- e.g. a no-op update -- leave `existing.configuration` as-is,
        // matching this RPC's original behavior (it only ever reconnected when a
        // `short_lived_user_access_token` was present).
        _ => {}
    }
    existing.updated_at = Some(SystemTime::now());

    let updated = diesel::update(sync_destinations::table.filter(sync_destinations::id.eq(existing.id)))
        .set(&existing)
        .get_result::<models::SyncDestination>(conn)
        .map_err(|e| {
            log::error!("Failed to update sync destination: {:?}", e);
            Status::new(Code::Internal, "failed_to_update_sync_destination")
        })?;

    let owner = models::get_author(updated.user_id, conn)?;
    let mut proto = MarshalableSyncDestination(updated, owner).to_proto();
    attach_synced_counts(std::slice::from_mut(&mut proto), conn);
    Ok(proto)
}
