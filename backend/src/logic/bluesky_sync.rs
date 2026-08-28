//! Connects a `SyncDestination` to a Bluesky (AT Protocol) account via an "App Password" (not the
//! account's main password) and posts `EventInstance`s/`Post`s to it as a `app.bsky.feed.post`
//! record.
//!
//! Sessions are created fresh per post rather than stored/refreshed -- App Passwords don't expire,
//! so re-authenticating on every `post_record` call is simpler than session-refresh bookkeeping and
//! avoids session-expiry bugs entirely.

use tonic::{Code, Status};

use crate::logic::http_client::blocking_json_request;
use crate::logic::sync_message::truncate_for_bluesky;
use crate::logic::SyncMessage;
use crate::models;

const DEFAULT_BASE_URL: &str = "https://bsky.social";

/// Authenticates `handle`/`app_password` against Bluesky, returning `(did, access_jwt)`. Used both
/// to validate a `BlueskyAccount` on connect (`CreateSyncDestination`/`UpdateSyncDestination`, which
/// only need the `did`) and fresh before every `post_record` call (which also needs the
/// `access_jwt`).
pub fn create_session(handle: &str, app_password: &str) -> Result<(String, String), Status> {
    create_session_at(DEFAULT_BASE_URL, handle, app_password)
}

/// Same as `create_session`, but against an arbitrary `base_url` -- lets specs point this at a
/// local mock server instead of the real Bluesky API (see `factories::serve_bluesky_api`).
pub fn create_session_at(
    base_url: &str,
    handle: &str,
    app_password: &str,
) -> Result<(String, String), Status> {
    let url = format!("{base_url}/xrpc/com.atproto.server.createSession");
    let body = serde_json::json!({ "identifier": handle, "password": app_password });
    let (status, response) = blocking_json_request(
        move |client| client.post(&url).json(&body),
        "bluesky_request_failed",
    )?;
    if !status.is_success() {
        log::error!("Bluesky createSession failed ({}): {:?}", status, response);
        return Err(Status::new(
            Code::FailedPrecondition,
            "bluesky_credentials_invalid",
        ));
    }
    let did = response
        .get("did")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!("Bluesky createSession response missing did: {:?}", response);
            Status::new(Code::FailedPrecondition, "bluesky_credentials_invalid")
        })?;
    let access_jwt = response
        .get("accessJwt")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Bluesky createSession response missing accessJwt: {:?}",
                response
            );
            Status::new(Code::FailedPrecondition, "bluesky_credentials_invalid")
        })?;
    Ok((did, access_jwt))
}

/// Posts an already-built `SyncMessage` to `destination`'s connected Bluesky account as a new
/// `app.bsky.feed.post` record. `message.text` is truncated to Bluesky's ~300-character limit
/// first (see `truncate_for_bluesky`) -- the one platform truncated proactively client-side rather
/// than surfacing the API's own rejection, since Bluesky's limit is fixed and known (unlike
/// Mastodon's, which varies per instance). Returns the record's `at://` URI and a human-clickable
/// `https://bsky.app/...` permalink built from it.
pub fn post_record(
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    post_record_at(DEFAULT_BASE_URL, destination, message)
}

/// Same as `post_record`, but against an arbitrary `base_url` -- see `create_session_at`.
pub fn post_record_at(
    base_url: &str,
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    let not_configured =
        || Status::new(Code::FailedPrecondition, "sync_destination_not_configured");
    let bluesky_account = destination
        .configuration
        .get("bluesky_account")
        .ok_or_else(not_configured)?;
    let handle = bluesky_account
        .get("handle")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;
    let app_password = bluesky_account
        .get("app_password")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;

    let (did, access_jwt) = create_session_at(base_url, handle, app_password)?;

    let text = truncate_for_bluesky(&message.text);
    let created_at = chrono::Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true);
    let record_body = serde_json::json!({
        "repo": did,
        "collection": "app.bsky.feed.post",
        "record": {
            "$type": "app.bsky.feed.post",
            "text": text,
            "createdAt": created_at,
        }
    });
    let url = format!("{base_url}/xrpc/com.atproto.repo.createRecord");
    let (status, response) = blocking_json_request(
        move |client| client.post(&url).bearer_auth(access_jwt).json(&record_body),
        "bluesky_request_failed",
    )?;
    if !status.is_success() {
        log::error!("Bluesky createRecord failed ({}): {:?}", status, response);
        return Err(Status::new(Code::FailedPrecondition, "bluesky_post_failed"));
    }
    let uri = response
        .get("uri")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Bluesky createRecord response missing uri: {:?}",
                response
            );
            Status::new(Code::Internal, "bluesky_post_failed")
        })?;
    let record_key = uri.rsplit('/').next().unwrap_or("");
    let permalink = format!("https://bsky.app/profile/{did}/post/{record_key}");
    Ok((uri, permalink))
}
