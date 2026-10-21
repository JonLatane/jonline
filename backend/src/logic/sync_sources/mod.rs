mod event_sync;
pub use event_sync::*;

mod feed_sync;
pub use feed_sync::*;

mod stellarwp_sync;
pub use stellarwp_sync::*;

mod background_sync;
pub use background_sync::SyncQueue;

use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::models;

/// The `User-Agent` header `source`'s fetches send (its `user_agent` setting), if any. Some feeds
/// sit behind bot protection that only admits certain clients -- raleighnc.gov's Cloudflare rules
/// let `curl/*` through and challenge everything else, including a request with no `User-Agent`.
pub fn user_agent_header(source: &models::SyncSource) -> Option<&'static str> {
    match crate::marshaling::user_agent_from_db(&source.user_agent) {
        crate::protos::SyncSourceUserAgent::NoUserAgent => None,
        crate::protos::SyncSourceUserAgent::Rellm => Some("Rellm-SyncSource/1.0 (+https://rellm.org)"),
        crate::protos::SyncSourceUserAgent::Curl => Some("curl/8.7.1"),
    }
}

/// A `reqwest` client builder carrying `source`'s `User-Agent` setting -- what every sync source
/// type's HTTP fetch starts from. (Like any `reqwest::blocking` client it must be built, and used,
/// inside the callers' `block_in_place` wrapper.)
pub(super) fn client_builder(source: &models::SyncSource) -> reqwest::blocking::ClientBuilder {
    let builder = reqwest::blocking::Client::builder();
    match user_agent_header(source) {
        Some(user_agent) => builder.user_agent(user_agent),
        None => builder,
    }
}

fn has_config_string(source: &models::SyncSource, key: &str) -> bool {
    source
        .configuration
        .get(key)
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty())
        .is_some()
}

/// Dispatches a `SyncSource` sync to its underlying implementation based on which
/// `configuration` variant is set: `event_sync::sync_source_ics` for an ICS subscription
/// (creates/updates Events/Occasions), `stellarwp_sync::sync_source_stellarwp` for a paginated
/// StellarWP "The Events Calendar" iCal URL (also Events/Occasions), or
/// `feed_sync::sync_source_feed` for an RSS or Atom subscription (creates/updates plain Posts) --
/// both RSS and Atom dispatch to the same feed-sync implementation, since `feed-rs` parses either
/// format into one unified shape.
pub fn sync_source(source: &models::SyncSource, conn: &mut PgPooledConnection) -> Result<(), Status> {
    if has_config_string(source, "ics_subscription_url") {
        return event_sync::sync_source_ics(source, conn);
    }
    if has_config_string(source, "stellarwp_ics_subscription_url") {
        return stellarwp_sync::sync_source_stellarwp(source, conn);
    }
    if source.configuration.get("rss_subscription_url").is_some()
        || source.configuration.get("atom_subscription_url").is_some()
    {
        return feed_sync::sync_source_feed(source, conn);
    }
    Err(Status::new(
        Code::FailedPrecondition,
        "sync_source_configuration_required",
    ))
}

/// Syncs a just-created or just-edited `SyncSource` -- what `create_sync_source`/
/// `update_sync_source` call, with a person waiting on the response. Same as [`sync_source`],
/// except a paginated StellarWP source (which can take a minute or more to fetch in full) only
/// syncs its first page inline; the rest is synced on the background worker (see
/// [`background_sync`]), so the response isn't held up. Errors in the background sync are
/// logged; the next scheduled sync (`bin/sync_sources`) retries.
pub fn sync_source_after_edit(
    source: &models::SyncSource,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    if has_config_string(source, "stellarwp_ics_subscription_url") {
        stellarwp_sync::sync_source_stellarwp_first_page(source, conn)?;
        background_sync::request_background_sync(source.id);
        return Ok(());
    }
    sync_source(source, conn)
}
