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
