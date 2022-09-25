use std::time::SystemTime;

use crate::schema::server_configurations;
use crate::schema::users;
use crate::schema::posts;

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct ServerConfiguration {
    pub id: i32,
    
    pub server_info: serde_json::Value,
    pub default_user_permissions: serde_json::Value,
    pub post_defaults: serde_json::Value,
    pub event_defaults: serde_json::Value,

    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct User {
    pub id: i32,
    pub username: String,
    pub password_salted_hash: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub permissions: serde_json::Value,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Post {
    pub id: i32,
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub moderation_status: String,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub response_count: i32,
    pub reply_count: i32,
    pub preview: Option<Vec<u8>>
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
#[table_name = "posts"]
pub struct MinimalPost {
    pub id: i32,
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub response_count: i32,
    pub reply_count: i32
}

pub static MINIMAL_POST_COLUMNS: (
    posts::id,
    posts::user_id,
    posts::parent_post_id,
    posts::title,
    posts::link,
    posts::content,
    posts::created_at,
    posts::updated_at,
    posts::response_count,
    posts::reply_count,
) = (
    posts::id,
    posts::user_id,
    posts::parent_post_id,
    posts::title,
    posts::link,
    posts::content,
    posts::created_at,
    posts::updated_at,
    posts::response_count,
    posts::reply_count,
);

#[derive(Debug, Insertable)]
#[table_name = "posts"]
pub struct NewPost {
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub preview: Option<Vec<u8>>
}
