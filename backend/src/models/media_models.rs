use std::time::SystemTime;

use tonic::{Status, Code};
use diesel::*;

use crate::{schema::{media}, db_connection::PgPooledConnection};

pub fn get_media(media_id: i64, conn: &mut PgPooledConnection,) -> Result<Media, Status> {
    media::table
        .select(media::all_columns)
        .filter(media::id.eq(media_id))
        .first::<Media>(conn)
        .map_err(|_| Status::new(Code::NotFound, "media_not_found"))
}

// Group Media, when/if implemented, will probably go along a "Group designated User's Media" route,
// rather than how Group Posts and Group Events work. This is because Media is a layer "under" Posts and Events.

// pub fn get_group_media(group_id: i64, media_id: i32, conn: &mut PgPooledConnection,) -> Result<GroupMedia, Status> {
//     group_posts::table
//         .select(group_posts::all_columns)
//         .filter(group_posts::group_id.eq(group_id))
//         .filter(group_posts::media_id.eq(media_id))
//         .first::<GroupMedia>(conn)
//         .map_err(|_| Status::new(Code::NotFound, "group_media_not_found"))
// }

#[derive(Debug, Queryable, Identifiable, AsChangeset)]
#[diesel(table_name = media)]
pub struct Media {
    pub id: i64,
    pub user_id: Option<i64>,
    pub minio_path: String,
    pub content_type: String,
    pub name: Option<String>,
    pub description: Option<String>,
    pub visibility: String,
    pub moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = media)]
pub struct NewMedia {
    pub user_id: Option<i64>,
    pub minio_path: String,
    pub content_type: String,
    pub name: Option<String>,
    pub description: Option<String>,
    pub visibility: String,
}
