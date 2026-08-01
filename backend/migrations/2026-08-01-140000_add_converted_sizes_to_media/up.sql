-- thumbnail_minio_path/thumbnail_content_type were never populated by any code path (grep finds
-- only their schema.rs/media_models.rs declarations) -- replaced here by converted_sizes, a
-- single JSONB column holding all auto-generated resized copies of a Media item, of the shape:
--   { "small": {"minio_path": "...", "content_type": "..."}, "medium": ..., "large": ... }
-- (see models::media_models::{ConvertedSizeSpec, ConvertedSize, ConvertedSizes}). A size key is
-- omitted entirely if the original media is already at or below that size's max dimension, so
-- absence means "fall back to the original", not "not yet processed" (that's `processed` below).
-- Populated by the bin/convert_media_sizes.rs background job.
ALTER TABLE media DROP COLUMN thumbnail_minio_path;
ALTER TABLE media DROP COLUMN thumbnail_content_type;
ALTER TABLE media ADD COLUMN converted_sizes JSONB NOT NULL DEFAULT '{}';
