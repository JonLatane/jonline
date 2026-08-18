-- Data-only migration. The `aspect_ratio` backfill (2026-08-17-214938_add_aspect_ratio_to_media)
-- shipped before logic::media_conversion::ImageMagick::dimensions accounted for EXIF orientation
-- (and FFmpeg::dimensions for rotation side data/tags), so any row it already ran against got a
-- wrong value -- e.g. a portrait photo stored with landscape pixel data plus a rotate tag (very
-- common; most cameras never physically rotate the pixels) was recorded at the un-rotated,
-- landscape ratio. Clearing it back to NULL lets convert_media_sizes' `processed = true AND
-- aspect_ratio IS NULL` backfill sweep (see media_pending_conversion) recompute it correctly.
UPDATE media SET aspect_ratio = NULL WHERE aspect_ratio IS NOT NULL;
