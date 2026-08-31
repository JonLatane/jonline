//! Connects a `SyncDestination` to a Facebook Page (OAuth token exchange) and posts
//! `EventInstance`s/`Post`s to it via the Graph API.
//!
//! For `EventInstance`s, this creates a Page **post** formatted to read like an event
//! announcement (title, date/time range -- in the event location's local timezone if
//! `logic::resolve_timezone` can geocode it, else UTC -- location, description, and a link back
//! to the event on this Jonline server), not a real Facebook **Event** object -- the Graph API's
//! `event` node has been creation/update/delete-locked for third-party apps since v3.3 (2018),
//! restricted to approved Facebook Marketing Partners. See `docs/facebook_and_x_twitter_federation.md` for the
//! full rundown of why and what this does instead. `Post`s are simpler -- just title/content and
//! a link back to the post -- see `post_post`.
//!
//! Posting to a user's personal timeline isn't possible via the Graph API (Facebook deprecated
//! `publish_actions` in 2018) -- only to a Page the user administers, hence `SyncDestination` only
//! supports `FacebookPage`, not a personal profile.
//!
//! Needs this app's own Facebook App ID/Secret (an admin-configured
//! `ServerConfiguration.federation_info.facebook_auth_config`, not an env var -- callers fetch it
//! via `server_facebook_app_credentials` and pass it in) to extend the short-lived user access
//! token the client gets from Facebook Login into a long-lived Page access token -- see
//! `connect_facebook_page`. A Page access token obtained this way is effectively non-expiring (it
//! lasts until the user revokes access or changes their Facebook password), so it's stored once
//! and reused indefinitely.

use serde_json::Value;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{MediaAttachment, SyncMessage};
use crate::models;
use crate::protos::FederationInfo;

const GRAPH_API_VERSION: &str = "v19.0";
const DEFAULT_GRAPH_API_BASE_URL: &str = "https://graph.facebook.com";

#[derive(Debug)]
pub struct FacebookPageConnection {
    pub page_id: String,
    pub page_name: String,
    pub access_token: String,
}

/// Loads this server's own Facebook App ID/Secret, as configured by an admin via `ConfigureServer`
/// (`ServerConfiguration.federation_info.facebook_auth_config`) -- required before any
/// `connect_facebook_page`/`connect_facebook_page_at` call. Reads the raw DB model (not
/// `get_server_configuration_proto`), since that always blanks `app_secret` for client responses
/// (see `ToProtoServerConfiguration`) -- this needs the real value.
pub fn server_facebook_app_credentials(
    conn: &mut PgPooledConnection,
) -> Result<(String, String), Status> {
    let configuration = crate::rpcs::get_server_configuration_model(conn)?;
    let federation_info: FederationInfo = serde_json::from_value(configuration.federation_info)
        .map_err(|e| {
            log::error!("Failed to parse stored federation_info: {:?}", e);
            Status::new(Code::Internal, "failed_to_load_server_configuration")
        })?;
    federation_info
        .facebook_auth_config
        .filter(|c| !c.app_id.is_empty() && !c.app_secret.is_empty())
        .map(|c| (c.app_id, c.app_secret))
        .ok_or_else(|| Status::new(Code::FailedPrecondition, "facebook_app_not_configured"))
}

/// Exchanges a short-lived user access token (from client-side Facebook Login) for `page_id`'s
/// long-lived Page access token: extends the user token, then looks up the Page's own token from
/// `/me/accounts` (which only lists Pages the user administers). `app_id`/`app_secret` are this
/// Jonline server's own Facebook App credentials -- see the module doc.
pub fn connect_facebook_page(
    app_id: &str,
    app_secret: &str,
    short_lived_user_access_token: &str,
    page_id: &str,
) -> Result<FacebookPageConnection, Status> {
    connect_facebook_page_at(
        DEFAULT_GRAPH_API_BASE_URL,
        app_id,
        app_secret,
        short_lived_user_access_token,
        page_id,
    )
}

/// Same as `connect_facebook_page`, but against an arbitrary `base_url` -- lets specs point this
/// at a local mock server instead of the real Graph API (see `factories::serve_facebook_graph_api`).
/// `pub` (not `#[cfg(test)]`) purely so it stays usable if a real proxy/base-URL override is ever
/// needed in production too.
pub fn connect_facebook_page_at(
    base_url: &str,
    app_id: &str,
    app_secret: &str,
    short_lived_user_access_token: &str,
    page_id: &str,
) -> Result<FacebookPageConnection, Status> {
    let long_lived_user_token = exchange_long_lived_user_token(
        base_url,
        app_id,
        app_secret,
        short_lived_user_access_token,
    )?;
    find_page_access_token(base_url, &long_lived_user_token, page_id)
}

fn exchange_long_lived_user_token(
    base_url: &str,
    app_id: &str,
    app_secret: &str,
    short_lived_token: &str,
) -> Result<String, Status> {
    let url = format!("{}/{}/oauth/access_token", base_url, GRAPH_API_VERSION);
    let response = graph_get(
        &url,
        &[
            ("grant_type", "fb_exchange_token"),
            ("client_id", app_id),
            ("client_secret", app_secret),
            ("fb_exchange_token", short_lived_token),
        ],
    )?;
    response
        .get("access_token")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Facebook token exchange response missing access_token: {:?}",
                response
            );
            Status::new(Code::FailedPrecondition, "facebook_token_exchange_failed")
        })
}

fn find_page_access_token(
    base_url: &str,
    long_lived_user_token: &str,
    page_id: &str,
) -> Result<FacebookPageConnection, Status> {
    let url = format!("{}/{}/me/accounts", base_url, GRAPH_API_VERSION);
    let response = graph_get(&url, &[("access_token", long_lived_user_token)])?;
    let pages = response
        .get("data")
        .and_then(|v| v.as_array())
        .ok_or_else(|| {
            log::error!(
                "Facebook /me/accounts response missing data: {:?}",
                response
            );
            Status::new(Code::FailedPrecondition, "facebook_pages_lookup_failed")
        })?;
    let page = pages
        .iter()
        .find(|p| p.get("id").and_then(|v| v.as_str()) == Some(page_id))
        .ok_or_else(|| Status::new(Code::PermissionDenied, "facebook_page_not_managed_by_user"))?;

    let page_name = page
        .get("name")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    let access_token = page
        .get("access_token")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| Status::new(Code::FailedPrecondition, "facebook_page_token_missing"))?;

    Ok(FacebookPageConnection {
        page_id: page_id.to_string(),
        page_name,
        access_token,
    })
}

/// Posts an `EventInstance`'s details (already formatted into `message.text` -- see
/// `logic::sync_message::build_event_instance_message`) to `destination`'s connected Facebook
/// Page's feed (there is no real Facebook "Event" created -- see the module doc). Returns the new
/// post's ID and a link to it.
pub fn post_event_instance(
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    post_event_instance_at(DEFAULT_GRAPH_API_BASE_URL, destination, message)
}

/// Same as `post_event_instance`, but against an arbitrary `base_url` -- see
/// `connect_facebook_page_at`.
pub fn post_event_instance_at(
    base_url: &str,
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    post_to_facebook_page(
        base_url,
        destination,
        message,
        "sync_destination_not_configured",
    )
}

/// Posts a `Post`'s details (already formatted into `message.text` -- see
/// `logic::sync_message::build_post_message`) to `destination`'s connected Facebook Page's feed.
/// Returns the new post's ID and a link to it. Functionally identical to `post_event_instance` --
/// kept as its own named function (rather than having `sync_post.rs` call `post_event_instance`
/// directly) purely so each call site's name mirrors the RPC it's dispatched from (`SyncPost` vs
/// `SyncEventInstance`), matching every other platform's naming convention.
pub fn post_post(
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    post_post_at(DEFAULT_GRAPH_API_BASE_URL, destination, message)
}

/// Same as `post_post`, but against an arbitrary `base_url` -- see `connect_facebook_page_at`.
pub fn post_post_at(
    base_url: &str,
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    post_to_facebook_page(
        base_url,
        destination,
        message,
        "sync_destination_not_configured",
    )
}

/// Shared implementation of `post_event_instance_at`/`post_post_at` -- now that both take a plain
/// `&SyncMessage`, there's nothing left distinguishing an EventInstance push from a Post push at
/// all (see each function's own doc for why two names still exist).
///
/// The Page Graph API doesn't support mixing photo attachments and a plain text `/feed` call the
/// way Instagram/Threads' single-container flow does -- these are structurally different
/// mechanisms, so `message.media` is dispatched into one of three shapes:
/// - No media: today's original behavior -- `/feed` with `message`/`link`.
/// - One or more images: each is first uploaded *unpublished* via `/photos` (returning a
///   `photo_id`), then `/feed` is called once with `message` and one indexed
///   `attached_media[N]={"media_fbid":"<photo_id>"}` field per photo (the documented Graph API
///   multi-photo-post pattern). `link` is dropped here -- Facebook's UI doesn't show a
///   link-preview card alongside photo attachments anyway.
/// - Video (and no images): posted via the dedicated `/videos` endpoint instead of `/feed`
///   entirely, using `file_url`/`description`.
/// - Both images and video present: Facebook can't do both in one call, so the video path wins
///   and the images are silently dropped -- a real platform limitation, not a bug to work around.
fn post_to_facebook_page(
    base_url: &str,
    destination: &models::SyncDestination,
    message: &SyncMessage,
    not_configured_error: &'static str,
) -> Result<(String, String), Status> {
    let not_configured = || Status::new(Code::FailedPrecondition, not_configured_error);
    let facebook_page = destination
        .configuration
        .get("facebook_page")
        .ok_or_else(not_configured)?;
    let page_id = facebook_page
        .get("page_id")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;
    let access_token = facebook_page
        .get("access_token")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;

    let images: Vec<&MediaAttachment> = message.media.iter().filter(|m| m.is_image()).collect();
    let video = message.media.iter().find(|m| m.is_video());

    if let Some(video) = video.filter(|_| images.is_empty()) {
        return post_video_to_facebook_page(base_url, page_id, access_token, message, video);
    }
    if !images.is_empty() {
        return post_photos_to_facebook_page(base_url, page_id, access_token, message, &images);
    }

    let url = format!("{}/{}/{}/feed", base_url, GRAPH_API_VERSION, page_id);
    let mut params = vec![
        ("message", message.text.as_str()),
        ("access_token", access_token),
    ];
    if let Some(link) = message.link.as_ref().filter(|l| !l.trim().is_empty()) {
        params.push(("link", link.as_str()));
    }
    let response = graph_post(&url, &params)?;
    extract_facebook_post_id_and_url(&response)
}

fn post_video_to_facebook_page(
    base_url: &str,
    page_id: &str,
    access_token: &str,
    message: &SyncMessage,
    video: &MediaAttachment,
) -> Result<(String, String), Status> {
    let url = format!("{}/{}/{}/videos", base_url, GRAPH_API_VERSION, page_id);
    let response = graph_post(
        &url,
        &[
            ("file_url", video.url.as_str()),
            ("description", message.text.as_str()),
            ("access_token", access_token),
        ],
    )?;
    let video_id = response
        .get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!("Facebook video post response missing id: {:?}", response);
            Status::new(Code::Internal, "facebook_post_failed")
        })?;
    // Prefer the response's own permalink if the Graph API returns one for this call -- more
    // reliable than hand-building the URL -- else fall back to the conventional `/videos/<id>`
    // shape.
    let video_url = response
        .get("permalink_url")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .unwrap_or_else(|| format!("https://www.facebook.com/{}/videos/{}", page_id, video_id));
    Ok((video_id, video_url))
}

fn post_photos_to_facebook_page(
    base_url: &str,
    page_id: &str,
    access_token: &str,
    message: &SyncMessage,
    images: &[&MediaAttachment],
) -> Result<(String, String), Status> {
    let photos_url = format!("{}/{}/{}/photos", base_url, GRAPH_API_VERSION, page_id);
    let mut photo_ids = Vec::with_capacity(images.len());
    for image in images {
        let response = graph_post(
            &photos_url,
            &[
                ("url", image.url.as_str()),
                ("published", "false"),
                ("access_token", access_token),
            ],
        )?;
        let photo_id = response
            .get("id")
            .and_then(|v| v.as_str())
            .map(str::to_string)
            .ok_or_else(|| {
                log::error!("Facebook photo upload response missing id: {:?}", response);
                Status::new(Code::Internal, "facebook_post_failed")
            })?;
        photo_ids.push(photo_id);
    }

    let feed_url = format!("{}/{}/{}/feed", base_url, GRAPH_API_VERSION, page_id);
    let mut owned_params: Vec<(String, String)> = vec![
        ("message".to_string(), message.text.clone()),
        ("access_token".to_string(), access_token.to_string()),
    ];
    for (i, photo_id) in photo_ids.iter().enumerate() {
        owned_params.push((
            format!("attached_media[{i}]"),
            serde_json::json!({ "media_fbid": photo_id }).to_string(),
        ));
    }
    let params: Vec<(&str, &str)> = owned_params
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();
    let response = graph_post(&feed_url, &params)?;
    extract_facebook_post_id_and_url(&response)
}

fn extract_facebook_post_id_and_url(response: &Value) -> Result<(String, String), Status> {
    let post_id = response
        .get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!("Facebook post response missing id: {:?}", response);
            Status::new(Code::Internal, "facebook_post_failed")
        })?;
    let post_url = format!("https://www.facebook.com/{}", post_id);
    Ok((post_id, post_url))
}

/// Looks up the Instagram Business/Creator account linked to `page_id` (via `page_access_token`,
/// the same long-lived Page token `connect_facebook_page` returns) -- required before posting to
/// Instagram, since posting piggybacks on the linked Page's token rather than a separate Instagram
/// login. Returns `(instagram_business_account_id, username)`.
pub fn get_linked_instagram_business_account(
    page_access_token: &str,
    page_id: &str,
) -> Result<(String, String), Status> {
    get_linked_instagram_business_account_at(DEFAULT_GRAPH_API_BASE_URL, page_access_token, page_id)
}

/// Same as `get_linked_instagram_business_account`, but against an arbitrary `base_url` -- see
/// `connect_facebook_page_at`.
pub fn get_linked_instagram_business_account_at(
    base_url: &str,
    page_access_token: &str,
    page_id: &str,
) -> Result<(String, String), Status> {
    let url = format!("{}/{}/{}", base_url, GRAPH_API_VERSION, page_id);
    let response = graph_get(
        &url,
        &[
            ("fields", "instagram_business_account{id,username}"),
            ("access_token", page_access_token),
        ],
    )?;
    let account = response
        .get("instagram_business_account")
        .ok_or_else(|| {
            Status::new(
                Code::FailedPrecondition,
                "instagram_no_linked_business_account",
            )
        })?;
    let id = account
        .get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            Status::new(
                Code::FailedPrecondition,
                "instagram_no_linked_business_account",
            )
        })?;
    let username = account
        .get("username")
        .and_then(|v| v.as_str())
        .unwrap_or("")
        .to_string();
    Ok((id, username))
}

/// Posts an already-built `SyncMessage` to `destination`'s linked Instagram Business account.
/// Instagram's Graph API has **no text-only post type**, so this fails fast with
/// `instagram_requires_media` if `message.media` is empty rather than attempting the call. A
/// 2-step flow otherwise: create a media container (`/media`) from the first media URL + caption,
/// then publish it (`/media_publish`), then fetch the published media's real `permalink` (the
/// publish step only returns an opaque ID, not a link). Returns `(media_id, permalink)`.
pub fn post_to_instagram(
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    post_to_instagram_at(DEFAULT_GRAPH_API_BASE_URL, destination, message)
}

/// Same as `post_to_instagram`, but against an arbitrary `base_url` -- see
/// `connect_facebook_page_at`.
pub fn post_to_instagram_at(
    base_url: &str,
    destination: &models::SyncDestination,
    message: &SyncMessage,
) -> Result<(String, String), Status> {
    let Some(media) = message.media.first() else {
        return Err(Status::new(
            Code::FailedPrecondition,
            "instagram_requires_media",
        ));
    };

    let not_configured =
        || Status::new(Code::FailedPrecondition, "sync_destination_not_configured");
    let instagram_account = destination
        .configuration
        .get("instagram_account")
        .ok_or_else(not_configured)?;
    let ig_user_id = instagram_account
        .get("instagram_business_account_id")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;
    let access_token = instagram_account
        .get("access_token")
        .and_then(|v| v.as_str())
        .ok_or_else(not_configured)?;

    let create_url = format!("{}/{}/{}/media", base_url, GRAPH_API_VERSION, ig_user_id);
    let mut create_params: Vec<(&str, &str)> = vec![
        ("caption", message.text.as_str()),
        ("access_token", access_token),
    ];
    if media.is_video() {
        // Current Meta guidance routes single-video feed posts through the Reels container type
        // via the Graph API (there's no separate plain "feed video" media_type) -- if Meta's docs
        // have since introduced a dedicated non-Reels video post type, prefer that instead.
        create_params.push(("media_type", "REELS"));
        create_params.push(("video_url", media.url.as_str()));
    } else {
        // No `media_type` needed -- Instagram defaults to IMAGE.
        create_params.push(("image_url", media.url.as_str()));
    }
    let create_response = graph_post(&create_url, &create_params)?;
    let creation_id = create_response
        .get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Instagram media creation response missing id: {:?}",
                create_response
            );
            Status::new(Code::Internal, "instagram_post_failed")
        })?;

    let publish_url = format!(
        "{}/{}/{}/media_publish",
        base_url, GRAPH_API_VERSION, ig_user_id
    );
    let publish_response = graph_post(
        &publish_url,
        &[
            ("creation_id", creation_id.as_str()),
            ("access_token", access_token),
        ],
    )?;
    let media_id = publish_response
        .get("id")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Instagram media_publish response missing id: {:?}",
                publish_response
            );
            Status::new(Code::Internal, "instagram_post_failed")
        })?;

    let permalink_url = format!("{}/{}/{}", base_url, GRAPH_API_VERSION, media_id);
    let permalink_response = graph_get(
        &permalink_url,
        &[("fields", "permalink"), ("access_token", access_token)],
    )?;
    let permalink = permalink_response
        .get("permalink")
        .and_then(|v| v.as_str())
        .map(str::to_string)
        .ok_or_else(|| {
            log::error!(
                "Instagram media permalink lookup response missing permalink: {:?}",
                permalink_response
            );
            Status::new(Code::Internal, "instagram_post_failed")
        })?;

    Ok((media_id, permalink))
}

fn graph_get(url: &str, params: &[(&str, &str)]) -> Result<Value, Status> {
    graph_request(move |client| client.get(url).query(params))
}

fn graph_post(url: &str, params: &[(&str, &str)]) -> Result<Value, Status> {
    graph_request(move |client| client.post(url).form(params))
}

/// See `event_sync::fetch_ics` for why `block_in_place` is used (and only when there's already a
/// Tokio runtime -- plain `#[test]`s and `bin/`s have none, and `block_in_place` panics without
/// one).
fn graph_request(
    build: impl FnOnce(&reqwest::blocking::Client) -> reqwest::blocking::RequestBuilder + Send,
) -> Result<Value, Status> {
    crate::init_crypto();
    let call = move || {
        let client = reqwest::blocking::Client::new();
        let text = build(&client)
            .send()
            .map_err(|e| {
                log::error!("Facebook Graph API request failed: {:?}", e);
                Status::new(Code::FailedPrecondition, "facebook_request_failed")
            })?
            .text()
            .map_err(|e| {
                log::error!("Failed to read Facebook Graph API response body: {:?}", e);
                Status::new(Code::FailedPrecondition, "facebook_request_failed")
            })?;
        let value: Value = serde_json::from_str(&text).map_err(|e| {
            log::error!(
                "Failed to parse Facebook Graph API response as JSON: {:?} ({})",
                e,
                text
            );
            Status::new(Code::FailedPrecondition, "facebook_request_failed")
        })?;
        if let Some(error) = value.get("error") {
            log::error!("Facebook Graph API returned an error: {:?}", error);
            // Facebook's top-level `error.code` is a documented, stable field (unlike
            // `error_subcode`, which isn't) -- 190 is always an invalid/expired OAuth token, 368
            // is Facebook's "confirm your identity" checkpoint (surfaced to the Page admin via
            // the Facebook app/website, not something Jonline can resolve on the caller's
            // behalf). Both get their own message so the frontend can tell the user what to
            // actually do instead of a generic "something went wrong".
            let message = match error.get("code").and_then(|c| c.as_i64()) {
                Some(368) => "facebook_identity_verification_required",
                Some(190) => "facebook_token_expired",
                _ => "facebook_graph_api_error",
            };
            return Err(Status::new(Code::FailedPrecondition, message));
        }
        Ok(value)
    };

    if tokio::runtime::Handle::try_current().is_ok() {
        tokio::task::block_in_place(call)
    } else {
        call()
    }
}
