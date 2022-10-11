use std::time::SystemTime;

use crate::schema::{users, follows};

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct User {
    pub id: i32,
    pub username: String,
    pub password_salted_hash: String,
    pub email: Option<serde_json::Value>,
    pub phone: Option<serde_json::Value>,
    /// A serialized (by name) list of [crate::protos::Permission]s.
    pub permissions: serde_json::Value,
    pub avatar: Option<Vec<u8>>,
    pub visibility: String,
    pub moderation: String,
    pub default_follow_moderation: String,
    pub follower_count: i32,
    pub following_count: i32,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Follow {
    pub id: i32,
    pub user_id: i32,
    pub target_user_id: i32,
    pub target_user_moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[table_name = "follows"]
pub struct NewFollow {
    pub user_id: i32,
    pub target_user_id: i32,
    pub target_user_moderation: String,
}
