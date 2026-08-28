use std::time::SystemTime;

use super::{ToDbId, ToProtoAuthor, ToProtoId, ToProtoTime};
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;

#[derive(Debug, Clone)]
pub struct MarshalableSyncDestination(pub models::SyncDestination, pub models::Author);

pub trait ToProtoMarshalableSyncDestination {
    fn to_proto(&self) -> SyncDestination;
}

impl ToProtoMarshalableSyncDestination for MarshalableSyncDestination {
    fn to_proto(&self) -> SyncDestination {
        let destination = &self.0;
        let owner = &self.1;
        SyncDestination {
            id: destination.id.to_proto_id(),
            owner: Some(owner.to_proto(None)),
            created_at: Some(destination.created_at.to_proto()),
            updated_at: destination.updated_at.map(|t| t.to_proto()),
            // Left unset here -- see `attach_synced_counts`, which every RPC handler that returns
            // a `SyncDestination` calls as a second pass to fill these in (mirrors
            // `get_events.rs`'s "build the response, then attach_event_instance_attendances"
            // shape), rather than every caller of `to_proto` having to supply it up front.
            synced_event_instance_count: None,
            synced_post_count: None,
            configuration: destination_configuration_to_proto(&destination.configuration),
        }
    }
}

/// Second-pass attach step for `synced_event_instance_count`/`synced_post_count` -- batches two
/// `GROUP BY` queries (`models::get_sync_destination_synced_counts`/
/// `models::get_post_sync_destination_synced_counts`) across every destination in `destinations`
/// and mutates each in place, rather than each RPC handler querying per-row. Works the same for a
/// single freshly created/updated destination (pass a one-element slice, e.g. via
/// `std::slice::from_mut`) as it does for a whole `GetSyncDestinations` page.
pub fn attach_synced_counts(destinations: &mut [SyncDestination], conn: &mut PgPooledConnection) {
    let ids: Vec<i64> = destinations
        .iter()
        .filter_map(|d| d.id.to_db_id().ok())
        .collect();
    let event_instance_counts = models::get_sync_destination_synced_counts(ids.clone(), conn);
    let post_counts = models::get_post_sync_destination_synced_counts(ids, conn);
    for destination in destinations.iter_mut() {
        if let Ok(id) = destination.id.to_db_id() {
            destination.synced_event_instance_count =
                Some(event_instance_counts.get(&id).copied().unwrap_or(0) as u64);
            destination.synced_post_count = Some(post_counts.get(&id).copied().unwrap_or(0) as u64);
        }
    }
}

/// `configuration` JSONB shape today: `{"facebook_page": {"page_id": ..., "page_name": ...,
/// "access_token": ...}}` -- `access_token` is intentionally never surfaced here; it's
/// server-side only (see `logic::facebook_sync`).
pub fn destination_configuration_to_proto(
    configuration: &serde_json::Value,
) -> Option<sync_destination::Configuration> {
    let facebook_page = configuration.get("facebook_page")?;
    let page_id = facebook_page.get("page_id").and_then(|v| v.as_str())?;
    let page_name = facebook_page
        .get("page_name")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    Some(sync_destination::Configuration::FacebookPage(FacebookPage {
        page_id: page_id.to_string(),
        page_name: page_name.to_string(),
        short_lived_user_access_token: None,
    }))
}

/// Shared field-mapping for a single piece of content's (`EventInstance` or `Post`) sync status
/// against one `SyncDestination` -- both `models::EventInstanceSyncDestination` and
/// `models::PostSyncDestination` have identical shape (just `event_instance_id`/`post_id`
/// differs, which isn't even part of the output message), so this is the one place that maps
/// either into the shared `SyncDestinationStatus` proto.
pub fn to_proto_sync_destination_status(
    sync_destination_id: i64,
    destination_instance_id: Option<String>,
    destination_url: Option<String>,
    synced_at: Option<SystemTime>,
) -> SyncDestinationStatus {
    SyncDestinationStatus {
        sync_destination_id: sync_destination_id.to_proto_id(),
        destination_instance_id,
        destination_url,
        synced_at: synced_at.map(|t| t.to_proto()),
    }
}

pub trait ToProtoSyncDestinationStatus {
    fn to_proto(&self) -> SyncDestinationStatus;
}

impl ToProtoSyncDestinationStatus for models::EventInstanceSyncDestination {
    fn to_proto(&self) -> SyncDestinationStatus {
        to_proto_sync_destination_status(
            self.sync_destination_id,
            self.destination_instance_id.clone(),
            self.destination_url.clone(),
            self.synced_at,
        )
    }
}

impl ToProtoSyncDestinationStatus for models::PostSyncDestination {
    fn to_proto(&self) -> SyncDestinationStatus {
        to_proto_sync_destination_status(
            self.sync_destination_id,
            self.destination_instance_id.clone(),
            self.destination_url.clone(),
            self.synced_at,
        )
    }
}
