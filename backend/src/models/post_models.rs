use std::time::SystemTime;

use tonic::{Status, Code};
use diesel::*;

use crate::{schema::{posts, user_posts, group_posts}, db_connection::PgPooledConnection};

pub fn get_post(post_id: i64, conn: &mut PgPooledConnection,) -> Result<Post, Status> {
    posts::table
        .select(posts::all_columns)
        .filter(posts::id.eq(post_id))
        .first::<Post>(conn)
        .map_err(|_| Status::new(Code::NotFound, "post_not_found"))
}

pub fn get_group_post(group_id: i64, post_id: i64, conn: &mut PgPooledConnection,) -> Result<GroupPost, Status> {
    group_posts::table
        .select(group_posts::all_columns)
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::post_id.eq(post_id))
        .first::<GroupPost>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_post_not_found"))
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct Post {
    pub id: i64,
    pub user_id: Option<i64>,
    pub parent_post_id: Option<i64>,

    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,

    pub response_count: i32,
    pub reply_count: i32,
    pub group_count: i32,

    pub media: Vec<i64>,
    pub media_generated: bool,
    pub embed_link: bool,
    pub shareable: bool,

    pub context: String,
    pub visibility: String,
    pub moderation: String,

    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    pub published_at: Option<SystemTime>,
    pub last_activity_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = posts)]
pub struct NewPost {
    pub user_id: Option<i64>,
    pub parent_post_id: Option<i64>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub context: String,
    pub media: Vec<i64>,
}


#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct GroupPost {
    pub id: i64,
    pub group_id: i64,
    pub post_id: i64,
    pub user_id: i64,
    pub group_moderation: String,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = group_posts)]
pub struct NewGroupPost {
    pub group_id: i64,
    pub post_id: i64,
    pub user_id: i64,
    pub group_moderation: String,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
pub struct UserPost {
    pub id: i64,
    pub user_id: i64,
    pub post_id: i64,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}
#[derive(Debug, Insertable)]
#[diesel(table_name = user_posts)]
pub struct NewUserPost {
    pub user_id: i64,
    pub post_id: i64,
}
