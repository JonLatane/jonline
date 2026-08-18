use std::time::SystemTime;

use diesel::*;
use serde::{Deserialize, Serialize};
use tonic::{Code, Status};

use super::User;
use crate::{db_connection::PgPooledConnection, schema::media};

pub fn get_media(media_id: i64, conn: &mut PgPooledConnection) -> Result<Media, Status> {
    media::table
        .select(media::all_columns)
        .filter(media::id.eq(media_id))
        .first::<Media>(conn)
        .map_err(|_| Status::new(Code::NotFound, "media_not_found"))
}
pub fn get_media_reference(
    media_id: i64,
    conn: &mut PgPooledConnection,
) -> Result<MediaReference, Status> {
    media::table
        .select(MEDIA_REFERENCE_COLUMNS)
        .filter(media::id.eq(media_id))
        .first::<MediaReference>(conn)
        .map_err(|_| Status::new(Code::NotFound, "media_not_found"))
}
pub fn get_all_media(
    media_ids: Vec<i64>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MediaReference>, Status> {
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
    pub name: Option<String>,
    pub description: Option<String>,
    pub generated: bool,
    pub processed: bool,
    pub visibility: String,
    pub moderation: String,
    pub created_at: SystemTime,
    pub updated_at: SystemTime,
    pub converted_sizes: serde_json::Value,
    pub metadata: serde_json::Value,
    pub aspect_ratio: Option<f32>,
}

impl Media {
    /// Typed view of `converted_sizes`. Falls back to an empty (all-`None`) `ConvertedSizes` if
    /// the column somehow holds something that doesn't parse -- callers should treat that the
    /// same as "not converted yet" rather than erroring.
    pub fn converted_sizes(&self) -> ConvertedSizes {
        serde_json::from_value(self.converted_sizes.clone()).unwrap_or_default()
    }

    /// Typed view of `metadata`. Falls back to an empty (all-`None`) `MediaMetadata` if the
    /// column somehow holds something that doesn't parse.
    pub fn metadata(&self) -> MediaMetadata {
        serde_json::from_value(self.metadata.clone()).unwrap_or_default()
    }
}

/// `Media.metadata`'s typed shape: `{ video_preview_time_ms: 1000 }`. Currently just the
/// timestamp `MediaRenderer.elm` seeks video previews to (via a `#t=` Media Fragments URI);
/// absence means "use the browser's default first-frame preview".
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct MediaMetadata {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub video_preview_time_ms: Option<i64>,
}

/// Selects one of the auto-generated resized copies of a `Media` item's original upload. See
/// [`ConvertedSizes`] and `bin/convert_media_sizes.rs`, which populates them.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ConvertedSizeSpec {
    Small,
    Medium,
    Large,
}

impl ConvertedSizeSpec {
    pub const ALL: [ConvertedSizeSpec; 3] = [
        ConvertedSizeSpec::Small,
        ConvertedSizeSpec::Medium,
        ConvertedSizeSpec::Large,
    ];

    /// The max width/height (in pixels) media is resized to fit within for this size, preserving
    /// aspect ratio and never upscaling.
    pub fn max_dimension(&self) -> u32 {
        match self {
            ConvertedSizeSpec::Small => 320,
            ConvertedSizeSpec::Medium => 800,
            ConvertedSizeSpec::Large => 1600,
        }
    }

    /// Lowercase name, matching `converted_sizes`' JSON keys -- used to derive converted media's
    /// MinIO path and in logging.
    pub fn key(&self) -> &'static str {
        match self {
            ConvertedSizeSpec::Small => "small",
            ConvertedSizeSpec::Medium => "medium",
            ConvertedSizeSpec::Large => "large",
        }
    }
}

/// A single resized copy of a `Media` item's original upload, stored separately in MinIO.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConvertedSize {
    pub minio_path: String,
    pub content_type: String,
}

/// `Media.converted_sizes`' typed shape: `{ small: {...}, medium: {...}, large: {...} }`. A size
/// is `None` (and omitted from the JSON) when the original is already at or below that size's
/// `max_dimension` -- callers should fall back to the original `Media` in that case.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ConvertedSizes {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub small: Option<ConvertedSize>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub medium: Option<ConvertedSize>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub large: Option<ConvertedSize>,
}

impl ConvertedSizes {
    pub fn get(&self, spec: ConvertedSizeSpec) -> Option<&ConvertedSize> {
        match spec {
            ConvertedSizeSpec::Small => self.small.as_ref(),
            ConvertedSizeSpec::Medium => self.medium.as_ref(),
            ConvertedSizeSpec::Large => self.large.as_ref(),
        }
    }

    pub fn set(&mut self, spec: ConvertedSizeSpec, value: ConvertedSize) {
        match spec {
            ConvertedSizeSpec::Small => self.small = Some(value),
            ConvertedSizeSpec::Medium => self.medium = Some(value),
            ConvertedSizeSpec::Large => self.large = Some(value),
        }
    }
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
    pub metadata: serde_json::Value,
}

pub const MEDIA_REFERENCE_COLUMNS: (
    media::id,
    media::content_type,
    media::name,
    media::generated,
    media::metadata,
    media::aspect_ratio,
) = (
    media::id,
    media::content_type,
    media::name,
    media::generated,
    media::metadata,
    media::aspect_ratio,
);

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
#[diesel(table_name = media)]
pub struct MediaReference {
    pub id: i64,
    pub content_type: String,
    pub name: Option<String>,
    pub generated: bool,
    pub metadata: serde_json::Value,
    pub aspect_ratio: Option<f32>,
}

impl MediaReference {
    /// Typed view of `metadata`. See [`Media::metadata`].
    pub fn metadata(&self) -> MediaMetadata {
        serde_json::from_value(self.metadata.clone()).unwrap_or_default()
    }
}
