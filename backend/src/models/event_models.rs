use std::time::SystemTime;

use tonic::{Status, Code};
use diesel::*;

use crate::{schema::{events, event_instances}, db_connection::PgPooledConnection};

pub fn get_event(event_id: i32, conn: &mut PgPooledConnection,) -> Result<Event, Status> {
    events::table
        .select(events::all_columns)
        .filter(events::id.eq(event_id))
        .first::<Event>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_not_found"))
}

// pub fn get_group_event(group_id: i32, event_id: i32, conn: &mut PgPooledConnection,) -> Result<GroupEvent, Status> {
//     group_posts::table
//         .select(group_posts::all_columns)
//         .filter(group_posts::group_id.eq(group_id))
//         .filter(group_posts::event_id.eq(event_id))
//         .first::<GroupEvent>(conn)
//         .map_err(|_| Status::new(Code::NotFound, "group_event_not_found"))
// }

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Event {
    pub id: i32,
    pub post_id: i32,
    pub info: serde_json::Value,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = events)]
pub struct NewEvent {
    pub post_id: i32,
    pub info: serde_json::Value,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct EventInstance {
    pub id: i32,
    pub event_id: i32,
    pub post_id: Option<i32>,
    pub info: serde_json::Value,
    pub starts_at: SystemTime,
    pub ends_at: SystemTime,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = event_instances)]
pub struct NewEventInstance {
    pub event_id: i32,
    pub post_id: Option<i32>,
    pub info: serde_json::Value,
    pub starts_at: SystemTime,
    pub ends_at: SystemTime,
}

// #[derive(Debug, Queryable, Identifiable, AsChangeset)]
// pub struct GroupEvent {
//     pub id: i32,
//     pub group_id: i32,
//     pub event_id: i32,
//     pub user_id: i32,
//     pub group_moderation: String,
//     pub created_at: SystemTime,
//     pub updated_at: Option<SystemTime>,
// }
// #[derive(Debug, Insertable)]
// #[diesel(table_name = group_posts)]
// pub struct NewGroupEvent {
//     pub group_id: i32,
//     pub event_id: i32,
//     pub user_id: i32,
//     pub group_moderation: String,
// }

// #[derive(Debug, Queryable, Identifiable, AsChangeset)]
// pub struct UserEvent {
//     pub id: i32,
//     pub user_id: i32,
//     pub event_id: i32,
//     pub created_at: SystemTime,
//     pub updated_at: SystemTime,
// }
// #[derive(Debug, Insertable)]
// #[diesel(table_name = user_events)]
// pub struct NewUserEvent {
//     pub user_id: i32,
//     pub event_id: i32,
// }
