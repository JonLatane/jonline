mod event_sync;
pub use event_sync::*;

mod feed_sync;
pub use feed_sync::*;

mod stellarwp_sync;
pub use stellarwp_sync::*;

use std::collections::HashSet;
use std::sync::{LazyLock, Mutex};

use tonic::{Code, Status};

use crate::db_connection::{self, PgPooledConnection};
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
/// syncs its first page inline; the rest is synced on a background thread by
/// [`spawn_background_sync`], so the response isn't held up. Errors in the background sync are
/// logged; the next scheduled sync (`bin/sync_sources`) retries.
pub fn sync_source_after_edit(
    source: &models::SyncSource,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    if has_config_string(source, "stellarwp_ics_subscription_url") {
        stellarwp_sync::sync_source_stellarwp_first_page(source, conn)?;
        spawn_background_sync(source.id);
        return Ok(());
    }
    sync_source(source, conn)
}

/// Ids of `SyncSource`s with a background sync running, so a flurry of edits to one source runs
/// one full sync at a time rather than several racing to insert the same rows.
static BACKGROUND_SYNCS_IN_FLIGHT: LazyLock<Mutex<HashSet<i64>>> =
    LazyLock::new(|| Mutex::new(HashSet::new()));

/// Removes a source from [`BACKGROUND_SYNCS_IN_FLIGHT`] when dropped, even if the sync panics.
struct InFlightGuard(i64);

impl Drop for InFlightGuard {
    fn drop(&mut self) {
        if let Ok(mut in_flight) = BACKGROUND_SYNCS_IN_FLIGHT.lock() {
            in_flight.remove(&self.0);
        }
    }
}

/// Runs a full [`sync_source`] of `source_id` on a new thread with its own DB connection (the
/// RPC's connection goes back to the pool as soon as the handler returns). Reloads the source
/// first, so it syncs whatever configuration is current by the time the thread runs. A thread
/// rather than a child process: the server can't safely `fork` while multi-threaded, and the
/// sync code needs nothing a thread doesn't already have.
fn spawn_background_sync(source_id: i64) {
    match BACKGROUND_SYNCS_IN_FLIGHT.lock() {
        Ok(mut in_flight) => {
            if !in_flight.insert(source_id) {
                log::info!("Background sync of SyncSource {} already running.", source_id);
                return;
            }
        }
        Err(_) => return,
    }
    let guard = InFlightGuard(source_id);
    let spawned = std::thread::Builder::new()
        .name(format!("sync-source-{}", source_id))
        .spawn(move || {
            let _guard = guard;
            let pool = db_connection::establish_job_pool();
            let mut conn = match pool.get() {
                Ok(conn) => conn,
                Err(e) => {
                    log::error!(
                        "Background sync of SyncSource {} couldn't get a DB connection: {:?}",
                        source_id,
                        e
                    );
                    return;
                }
            };
            let source = match models::get_sync_source(source_id, &mut conn) {
                Ok(source) => source,
                Err(e) => {
                    // Deleted since the edit that spawned this -- nothing to sync.
                    log::info!("Background sync of SyncSource {} skipped: {:?}", source_id, e);
                    return;
                }
            };
            match sync_source(&source, &mut conn) {
                Ok(()) => log::info!("Background sync of SyncSource {} finished.", source_id),
                Err(e) => log::error!(
                    "Background sync of SyncSource {} failed: {:?}",
                    source_id,
                    e
                ),
            }
        });
    if let Err(e) = spawned {
        // `guard` was moved into the closure that never ran, and dropped with it.
        log::error!(
            "Failed to spawn background sync of SyncSource {}: {:?}",
            source_id,
            e
        );
    }
}
