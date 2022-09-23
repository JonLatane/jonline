use std::time::SystemTime;

use crate::schema::users;
use crate::schema::posts;

#[derive(Debug, Queryable, Insertable)]
#[table_name = "users"]
pub struct User {
    pub id: i32,
    pub username: String,
    pub password_salted_hash: String,
    pub email: Option<String>,
    pub phone: Option<String>,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Queryable, AsChangeset, Identifiable)]
// #[table_name = "posts"]
pub struct Post {
    pub id: i32,
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub reply_count: i32,
    pub preview: Option<Vec<u8>>
}

#[derive(Debug, Queryable, AsChangeset, Identifiable)]
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
    pub reply_count: i32,
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
