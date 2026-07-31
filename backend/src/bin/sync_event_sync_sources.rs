extern crate diesel;
extern crate jonline;
use std::time::{Duration, SystemTime};

use diesel::*;
use jonline::logic::sync_event_sync_source;
use jonline::models::EventSyncSource;
use jonline::schema::event_sync_sources;
use jonline::{db_connection, init_bin_logging, init_crypto};

pub fn main() {
    init_crypto();
    init_bin_logging();
    log::info!("Syncing Event Sync Sources...");
    log::info!("Connecting to DB...");
    let pool = db_connection::establish_pool();
    let mut conn = pool.get().expect("Failed to get DB connection");

    let sources = event_sync_sources::table
        .load::<EventSyncSource>(&mut conn)
        .expect("Failed to load EventSyncSources");

    let now = SystemTime::now();
    let due_sources: Vec<EventSyncSource> = sources
        .into_iter()
        .filter(|source| is_due(source, now))
        .collect();
    log::info!("{} EventSyncSource(s) due for sync.", due_sources.len());

    for source in due_sources {
        log::info!("Syncing EventSyncSource {}...", source.id);
        match sync_event_sync_source(&source, &mut conn) {
            Ok(()) => log::info!("Synced EventSyncSource {}.", source.id),
            Err(e) => log::error!(
                "Failed to sync EventSyncSource {}: {:?}. Proceeding through remaining sources.",
                source.id,
                e
            ),
        }
    }
    log::info!("Done Syncing Event Sync Sources.");
}

/// A source with no prior sync is always due. Otherwise it's due once
/// `sync_interval_seconds` has elapsed since `last_synced_at`.
fn is_due(source: &EventSyncSource, now: SystemTime) -> bool {
    match source.last_synced_at {
        None => true,
        Some(last_synced_at) => {
            let interval = Duration::from_secs(source.sync_interval_seconds as u64);
            match last_synced_at.checked_add(interval) {
                Some(next_sync_at) => now >= next_sync_at,
                None => true,
            }
        }
    }
}
