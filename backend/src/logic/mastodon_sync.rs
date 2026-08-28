//! Connects a `SyncDestination` to a Mastodon account (via a user-pasted Personal Access Token --
//! Mastodon instances are user-chosen arbitrary domains, so there's no single app to register ahead
//! of time the way Facebook has one) and posts `EventInstance`s/`Post`s to it as a status.
//!
//! No text-length truncation here -- unlike Bluesky's hard 300-grapheme limit, Mastodon's status
//! length limit varies per instance (the default is 500, but admins can raise or lower it), so
//! there's nothing sensible to guess-truncate to. A too-long status just surfaces as the API's own
//! 422 (`mastodon_post_failed`).

use tonic::{Code, Status};

use crate::logic::http_client::blocking_json_request;
use crate::logic::SyncMessage;
use crate::models;

/// Verifies `access_token` is a valid Personal Access Token for `instance_host`, returning the
/// account's username. Used both to validate a `MastodonAccount` on connect (`CreateSyncDestination`/
/// `UpdateSyncDestination`) and to populate `MastodonAccount.username` in the stored configuration.
pub fn verify_credentials(instance_host: &str, access_token: &str) -> Result<String, Status> {
    verify_credentials_at(&format!("https://{instance_host}"), access_token)
}

/// Same as `verify_credentials`, but against an arbitrary `base_url` -- lets specs point this at a
/// local mock server instead of a real Mastodon instance (see `factories::serve_mastodon_api`).
pub fn verify_credentials_at(base_url: &str, access_token: &str) -> Result<String, Status> {
    let url = format!("{base_url}/api/v1/accounts/verify_credentials");
    let (status, body) = blocking_json_request(
        move |client| client.get(&url).bearer_auth(access_token),
        "mastodon_request_failed",
    )?;
    if !status.is_success() {
        log::error!(
            "Mastodon verify_credentials failed ({}): {:?}",
            status,
            body
        );
        return Err(Status::new(
            Code::FailedPrecondition,
            "mastodon_token_invalid",
        ));
    }
    body.get("username")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Mastodon verify_credentials response missing username: {:?}",
                body
            );
            Status::new(Code::FailedPrecondition, "mastodon_token_invalid")
        })
}

/// Posts an already-built `SyncMessage` (`message.text` only -- no media upload this pass) to
/// `destination`'s connected Mastodon account as a new status. Returns the new status's ID and its
/// public permalink.
pub fn post_status(
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    let not_configured =
        || Status::new(Code::FailedPrecondition, "sync_destination_not_configured");
    let instance_host = destination
        .configuration
        .get("mastodon_account")
        .and_then(|c| c.get("instance_host"))
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;
    post_status_at(&format!("https://{instance_host}"), destination, message)
}

/// Same as `post_status`, but against an arbitrary `base_url` -- see `verify_credentials_at`.
pub fn post_status_at(
    base_url: &str,
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    let not_configured =
        || Status::new(Code::FailedPrecondition, "sync_destination_not_configured");
    let mastodon_account = destination
        .configuration
        .get("mastodon_account")
        .ok_or_else(not_configured)?;
    let access_token = mastodon_account
        .get("access_token")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;

    let url = format!("{base_url}/api/v1/statuses");
    let status_text = message.text.clone();
    let (status, body) = blocking_json_request(
        move |client| {
            client
                .post(&url)
                .bearer_auth(access_token)
                .form(&[("status", status_text.as_str())])
        },
        "mastodon_request_failed",
    )?;
    if !status.is_success() {
        log::error!("Mastodon post_status failed ({}): {:?}", status, body);
        return Err(Status::new(Code::FailedPrecondition, "mastodon_post_failed"));
    }
    let id = body
        .get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!("Mastodon post_status response missing id: {:?}", body);
            Status::new(Code::Internal, "mastodon_post_failed")
        })?;
    let url = body
        .get("url")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!("Mastodon post_status response missing url: {:?}", body);
            Status::new(Code::Internal, "mastodon_post_failed")
        })?;
    Ok((id, url))
}
