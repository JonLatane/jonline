use std::time::SystemTime;

use tonic::{Status, Code};
use diesel::*;

use crate::{schema::media, db_connection::PgPooledConnection};
use super::User;

pub fn get_media(media_id: i64, conn: &mut PgPooledConnection,) -> Result<Media, Status> {
    media::table
        .select(media::all_columns)
        .filter(media::id.eq(media_id))
        .first::<Media>(conn)
        .map_err(|_| Status::new(Code::NotFound, "media_not_found"))
}
pub fn get_media_reference(media_id: i64, conn: &mut PgPooledConnection,) -> Result<MediaReference, Status> {
    media::table
        .select(MEDIA_REFERENCE_COLUMNS)
        .filter(media::id.eq(media_id))
        .first::<MediaReference>(conn)
        .map_err(|_| Status::new(Code::NotFound, "media_not_found"))
}
pub fn get_all_media(media_ids: Vec<i64>, conn: &mut PgPooledConnection,) -> Result<Vec<MediaReference>, Status> {
    media::table
        .select(MEDIA_REFERENCE_COLUMNS)
        .filter(media::id.eq_any(media_ids))
        .load::<MediaReference>(conn)
        .map_err(|_| Status::new(Code::NotFound, "media_not_found"))
}

#[derive(Debug, Queryable, Identifiable, Associations, AsChangeset, Clone)]
#[diesel(belongs_to(User))]
#[diesel(table_name = media)]
pub struct Media {
    pub id: i64,
    pub user_id: Option<i64>,
    pub minio_path: String,
    pub content_type: String,
    pub thumbnail_minio_path: Option<String>,
    pub thumbnail_content_type: Option<String>,
    pub name: Option<String>,
    pub description: Option<String>,
    pub generated: bool,
    pub processed: bool,
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
    pub generated: bool,
    pub visibility: String,
}

pub const MEDIA_REFERENCE_COLUMNS: (
    media::id,
    media::content_type,
    media::name,
    media::generated,
) = (
    media::id,
    media::content_type,
    media::name,
    media::generated,
);

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
#[diesel(table_name = media)]
pub struct MediaReference {
    pub id: i64,
    pub content_type: String,
    pub name: Option<String>,
    pub generated: bool,
}