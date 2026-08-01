use std::time::SystemTime;

use diesel::*;

use crate::schema::{event_attendances, event_instances, event_sync_sources, events};

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
pub struct Event {
    pub id: i64,
    pub post_id: i64,
    pub info: serde_json::Value,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub event_sync_source_id: Option<i64>,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = events)]
pub struct NewEvent {
    pub post_id: i64,
    pub info: serde_json::Value,
    pub event_sync_source_id: Option<i64>,
}

#[derive(Debug, Queryable, Identifiable, Associations, AsChangeset, Clone)]
#[diesel(belongs_to(Event))]
pub struct EventInstance {
    pub id: i64,
    pub event_id: i64,
    pub post_id: i64,
    pub info: serde_json::Value,
    pub starts_at: SystemTime,
    pub ends_at: SystemTime,
    pub location: Option<serde_json::Value>,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub event_sync_source_instance_id: Option<String>,
    /// When this synced instance first stopped appearing in its `EventSyncSource`'s feed --
    /// `None` while it's present (or for instances never touched by sync). Gives it a grace
    /// period before `event_sync::reconcile_instances` actually deletes it, so a transient/partial
    /// upstream response can't permanently orphan the Post backing the instance's comment
    /// thread/media.
    pub sync_missing_since: Option<SystemTime>,
}

/// Explicit column list for `event_instances`, excluding:
/// - `search_text`, a denormalized tsvector used only for full-text search filtering/indexing --
///   see `backend/migrations/2026-07-30-170000_add_search_text_to_event_instances` -- mirroring
///   why `POST_COLUMNS` (`post_models.rs`) excludes `posts.search_text`.
/// - `user_id`, denormalized from the instance's own Post's author purely so a composite GIN
///   index can cover author-scoped search in one scan (see that same migration) -- never read
///   back into application code, and `EventInstance` derives `AsChangeset`, so a field here would
///   let a stray `.set(&existing_instance)` stomp the trigger-maintained value with stale data.
pub const EVENT_INSTANCE_COLUMNS: (
    event_instances::id,
    event_instances::event_id,
    event_instances::post_id,
    event_instances::info,
    event_instances::starts_at,
    event_instances::ends_at,
    event_instances::location,
    event_instances::created_at,
    event_instances::updated_at,
    event_instances::event_sync_source_instance_id,
    event_instances::sync_missing_since,
) = (
    event_instances::id,
    event_instances::event_id,
    event_instances::post_id,
    event_instances::info,
    event_instances::starts_at,
    event_instances::ends_at,
    event_instances::location,
    event_instances::created_at,
    event_instances::updated_at,
    event_instances::event_sync_source_instance_id,
    event_instances::sync_missing_since,
);

#[derive(Debug, Insertable)]
#[diesel(table_name = event_instances)]
pub struct NewEventInstance {
    pub event_id: i64,
    pub post_id: i64,
    pub info: serde_json::Value,
    pub starts_at: SystemTime,
    pub ends_at: SystemTime,
    pub location: Option<serde_json::Value>,
    pub event_sync_source_instance_id: Option<String>,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
pub struct EventSyncSource {
    pub id: i64,
    pub user_id: i64,
    pub sync_interval_seconds: i64,
    pub configuration: serde_json::Value,
    pub last_synced_at: Option<SystemTime>,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub event_count: i64,
    pub event_instance_count: i64,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = event_sync_sources)]
pub struct NewEventSyncSource {
    pub user_id: i64,
    pub sync_interval_seconds: i64,
    pub configuration: serde_json::Value,
}

#[derive(Debug, Queryable, Identifiable, Associations, AsChangeset, Clone)]
#[diesel(belongs_to(EventInstance))]
pub struct EventAttendance {
    pub id: i64,
    pub event_instance_id: i64,
    pub user_id: Option<i64>,
    pub anonymous_attendee: Option<serde_json::Value>,
    pub number_of_guests: i32,
    pub status: String,
    pub inviting_user_id: Option<i64>,
    pub public_note: String,
    pub private_note: String,
    pub moderation: String,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = event_attendances)]
pub struct NewEventAttendance {
    pub event_instance_id: i64,
    pub user_id: Option<i64>,
    pub anonymous_attendee: Option<serde_json::Value>,
    pub number_of_guests: i32,
    pub status: String,
    pub inviting_user_id: Option<i64>,
    pub public_note: String,
    pub private_note: String,
    pub moderation: String,
}

// #[derive(Debug, Queryable, Identifiable, AsChangeset)]
// pub struct GroupEvent {
//     pub id: i64,
//     pub group_id: i64,
//     pub event_id: i64,
//     pub user_id: i64,
//     pub group_moderation: String,
//     pub created_at: SystemTime,
//     pub updated_at: Option<SystemTime>,
// }
// #[derive(Debug, Insertable)]
// #[diesel(table_name = group_posts)]
// pub struct NewGroupEvent {
//     pub group_id: i64,
//     pub event_id: i64,
//     pub user_id: i64,
//     pub group_moderation: String,
// }

// #[derive(Debug, Queryable, Identifiable, AsChangeset)]
// pub struct UserEvent {
//     pub id: i64,
//     pub user_id: i64,
//     pub event_id: i64,
//     pub created_at: SystemTime,
//     pub updated_at: SystemTime,
// }
// #[derive(Debug, Insertable)]
// #[diesel(table_name = user_events)]
// pub struct NewUserEvent {
//     pub user_id: i64,
//     pub event_id: i64,
// }
