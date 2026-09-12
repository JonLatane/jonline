mod event_sync;
pub use event_sync::*;

mod feed_sync;
pub use feed_sync::*;

use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::models;

/// Dispatches a `SyncSource` sync to its underlying implementation based on which
/// `configuration` variant is set: `event_sync::sync_source_ics` for an ICS subscription
/// (creates/updates Events/Occasions), or `feed_sync::sync_source_feed` for an RSS or Atom
/// subscription (creates/updates plain Posts) -- both variants dispatch to the same feed-sync
/// implementation, since `feed-rs` parses either format into one unified shape.
pub fn sync_source(source: &models::SyncSource, conn: &mut PgPooledConnection) -> Result<(), Status> {
    if source
        .configuration
        .get("ics_subscription_url")
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty())
        .is_some()
    {
        return event_sync::sync_source_ics(source, conn);
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
