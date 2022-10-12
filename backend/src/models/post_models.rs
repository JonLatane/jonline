use std::time::SystemTime;

use crate::schema::posts;

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Post {
    pub id: i32,
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub moderation: String,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub response_count: i32,
    pub reply_count: i32,
    pub preview: Option<Vec<u8>>,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
#[diesel(table_name = posts)]
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
#[diesel(table_name = posts)]
pub struct NewPost {
    pub user_id: Option<i32>,
    pub parent_post_id: Option<i32>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub preview: Option<Vec<u8>>,
}
