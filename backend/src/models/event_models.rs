use std::time::SystemTime;

use diesel::*;

use crate::schema::{event_attendances, event_instances, events};

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
pub struct Event {
    pub id: i64,
    pub post_id: i64,
    pub info: serde_json::Value,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = events)]
pub struct NewEvent {
    pub post_id: i64,
    pub info: serde_json::Value,
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
}

#[derive(Debug, Insertable)]
#[diesel(table_name = event_instances)]
pub struct NewEventInstance {
    pub event_id: i64,
    pub post_id: i64,
    pub info: serde_json::Value,
    pub starts_at: SystemTime,
    pub ends_at: SystemTime,
    pub location: Option<serde_json::Value>,
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
