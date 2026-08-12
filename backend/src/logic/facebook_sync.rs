//! Connects an `EventSyncDestination` to a Facebook Page (OAuth token exchange) and posts
//! `EventInstance`s to it via the Graph API.
//!
//! This creates a Page **post** formatted to read like an event announcement (title, date/time
//! range -- in the event location's local timezone if `logic::resolve_timezone` can geocode it,
//! else UTC -- location, description, and a link back to the event on this Jonline server), not a
//! real Facebook **Event** object -- the Graph API's `event` node has been
//! creation/update/delete-locked for third-party apps since v3.3 (2018), restricted to approved
//! Facebook Marketing Partners. See `docs/facebook_federation.md` for the full rundown of why and
//! what this does instead.
//!
//! Posting to a user's personal timeline isn't possible via the Graph API (Facebook deprecated
//! `publish_actions` in 2018) -- only to a Page the user administers, hence `EventSyncDestination`
//! only supports `FacebookPage`, not a personal profile.
//!
//! Needs this app's own Facebook App ID/Secret (an admin-configured
//! `ServerConfiguration.federation_info.facebook_auth_config`, not an env var -- callers fetch it
//! via `server_facebook_app_credentials` and pass it in) to extend the short-lived user access
//! token the client gets from Facebook Login into a long-lived Page access token -- see
//! `connect_facebook_page`. A Page access token obtained this way is effectively non-expiring (it
//! lasts until the user revokes access or changes their Facebook password), so it's stored once
//! and reused indefinitely.

use chrono::{DateTime, Utc};
use serde_json::Value;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
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

/// Content for the Facebook Page post representing an `EventInstance` -- see `post_event_instance`.
/// Grouped into one struct (rather than more positional args) since several fields share the same
/// `Option<String>` shape and are easy to transpose by accident.
pub struct EventInstancePost<'a> {
    pub title: &'a Option<String>,
    pub content: &'a Option<String>,
    /// Arbitrary external link the organizer set on the underlying `Post` (e.g. a ticketing site).
    /// Used as the Graph API `link` (and thus the post's link-preview card) only if `event_url`
    /// isn't set.
    pub link: &'a Option<String>,
    pub starts_at: DateTime<Utc>,
    pub ends_at: DateTime<Utc>,
    /// `EventInstance.location`'s `uniformly_formatted_address`, if any.
    pub location: &'a Option<String>,
    /// The IANA timezone `location` resolves to, if `logic::resolve_timezone` could geocode it --
    /// see that function's doc comment. `starts_at`/`ends_at` are shown in this zone if set,
    /// otherwise in UTC.
    pub timezone: Option<chrono_tz::Tz>,
    /// Link to this event on this Jonline server's own frontend. Only buildable when
    /// `ServerConfiguration.external_cdn_config.frontend_host` is configured -- see
    /// `sync_event_instance`'s caller -- so this is `None` on servers without that set up.
    pub event_url: &'a Option<String>,
}

/// Posts an `EventInstance`'s details to `destination`'s connected Facebook Page's feed (there is
/// no real Facebook "Event" created -- see the module doc). Returns the new post's ID and a link
/// to it.
pub fn post_event_instance(
    destination: &models::EventSyncDestination,
    post: &EventInstancePost,
) -> Result<(String, String), Status> {
    post_event_instance_at(DEFAULT_GRAPH_API_BASE_URL, destination, post)
}

/// Same as `post_event_instance`, but against an arbitrary `base_url` -- see
/// `connect_facebook_page_at`.
pub fn post_event_instance_at(
    base_url: &str,
    destination: &models::EventSyncDestination,
    post: &EventInstancePost,
) -> Result<(String, String), Status> {
    let not_configured = || {
        Status::new(
            Code::FailedPrecondition,
            "event_sync_destination_not_configured",
        )
    };
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

    let message = format_message(post);
    let url = format!("{}/{}/{}/feed", base_url, GRAPH_API_VERSION, page_id);

    let mut params = vec![
        ("message", message.as_str()),
        ("access_token", access_token),
    ];
    let link = post
        .event_url
        .as_ref()
        .filter(|l| !l.trim().is_empty())
        .or_else(|| post.link.as_ref().filter(|l| !l.trim().is_empty()));
    if let Some(link) = link {
        params.push(("link", link.as_str()));
    }

    let response = graph_post(&url, &params)?;
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

fn format_message(post: &EventInstancePost) -> String {
    let mut lines = vec![];
    if let Some(title) = post.title.as_ref().filter(|t| !t.trim().is_empty()) {
        lines.push(title.clone());
    }
    let time_range = match post.timezone {
        Some(tz) => format_time_range(
            post.starts_at.with_timezone(&tz),
            post.ends_at.with_timezone(&tz),
        ),
        None => format_time_range(post.starts_at, post.ends_at),
    };
    lines.push(time_range);
    if let Some(location) = post.location.as_ref().filter(|l| !l.trim().is_empty()) {
        lines.push(format!("Location: {location}"));
    }
    if let Some(content) = post.content.as_ref().filter(|c| !c.trim().is_empty()) {
        lines.push(content.clone());
    }
    if let Some(event_url) = post.event_url.as_ref().filter(|l| !l.trim().is_empty()) {
        lines.push(format!("Details & RSVP: {event_url}"));
    }
    lines.join("\n\n")
}

/// Generic over the timezone (`Utc` or a `chrono_tz::Tz` the caller already converted `starts_at`
/// and `ends_at` into) so this doesn't need to duplicate itself for each.
fn format_time_range<Tz: chrono::TimeZone>(starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> String
where
    Tz::Offset: std::fmt::Display,
{
    let start_date = starts_at.format("%A, %B %-d, %Y").to_string();
    let start_time = starts_at.format("%-I:%M %p").to_string();
    let zone = starts_at.format("%Z").to_string();
    if ends_at <= starts_at {
        return format!("{start_date} at {start_time} {zone}");
    }
    if starts_at.date_naive() == ends_at.date_naive() {
        let end_time = ends_at.format("%-I:%M %p").to_string();
        format!("{start_date} at {start_time} \u{2013} {end_time} {zone}")
    } else {
        let end = ends_at.format("%A, %B %-d, %Y at %-I:%M %p %Z").to_string();
        format!("{start_date} at {start_time} {zone} \u{2013} {end}")
    }
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
            return Err(Status::new(
                Code::FailedPrecondition,
                "facebook_graph_api_error",
            ));
        }
        Ok(value)
    };

    if tokio::runtime::Handle::try_current().is_ok() {
        tokio::task::block_in_place(call)
    } else {
        call()
    }
}
