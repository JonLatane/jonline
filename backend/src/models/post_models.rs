use std::time::SystemTime;

use super::User;
use diesel::*;
use tonic::{Code, Status};

use crate::{
    db_connection::PgPooledConnection,
    schema::{group_posts, posts, user_posts},
};

pub fn get_post(post_id: i64, conn: &mut PgPooledConnection) -> Result<Post, Status> {
    posts::table
        .select(posts::all_columns)
        .filter(posts::id.eq(post_id))
        .first::<Post>(conn)
        .map_err(|_| Status::new(Code::NotFound, "post_not_found"))
}

pub fn get_group_post(
    group_id: i64,
    post_id: i64,
    conn: &mut PgPooledConnection,
) -> Result<GroupPost, Status> {
    group_posts::table
        .select(group_posts::all_columns)
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::post_id.eq(post_id))
        .first::<GroupPost>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_post_not_found"))
}

// numeric_expr!(posts::unauthenticated_star_count);

#[derive(Debug, Queryable, Identifiable, Associations, AsChangeset, Clone)]
#[diesel(belongs_to(User))]
#[diesel(treat_none_as_null = true)]
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

    pub media: Vec<Option<i64>>,
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

    pub unauthenticated_star_count: i64
}

#[derive(Debug, Insertable)]
#[diesel(table_name = posts)]
pub struct NewPost {
    pub user_id: Option<i64>,
    pub parent_post_id: Option<i64>,
    pub title: Option<String>,
    pub link: Option<String>,
    pub content: Option<String>,
    pub context: String,
    pub visibility: String,
    pub moderation: String,
    pub media: Vec<i64>,
    pub embed_link: bool,
}

#[derive(Debug, Queryable, Identifiable, Associations, AsChangeset, Clone)]
#[diesel(belongs_to(User))]
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
