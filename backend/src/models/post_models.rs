use std::time::SystemTime;

use crate::schema::{posts, user_posts, group_posts};

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
    pub response_count: i32,
    pub reply_count: i32,
    pub preview: Option<Vec<u8>>,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
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
    pub response_count: i32,
    pub reply_count: i32,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}

pub static MINIMAL_POST_COLUMNS: (
    posts::id,
    posts::user_id,
    posts::parent_post_id,
    posts::title,
    posts::link,
    posts::content,
    posts::response_count,
    posts::reply_count,
    posts::created_at,
    posts::updated_at,
) = (
    posts::id,
    posts::user_id,
    posts::parent_post_id,
    posts::title,
    posts::link,
    posts::content,
    posts::response_count,
    posts::reply_count,
    posts::created_at,
    posts::updated_at,
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


#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct GroupPost {
    pub id: i32,
    pub group_id: i32,
    pub post_id: i32,
    pub user_id: i32,
    pub group_moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = group_posts)]
pub struct NewGroupPost {
    pub group_id: i32,
    pub post_id: i32,
    pub user_id: i32,
    pub group_moderation: String,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct UserPost {
    pub id: i32,
    pub user_id: i32,
    pub post_id: i32,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = user_posts)]
pub struct NewUserPost {
    pub user_id: i32,
    pub post_id: i32,
}
