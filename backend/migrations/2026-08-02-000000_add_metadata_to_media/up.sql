-- A single JSONB column holding free-form per-Media metadata, of the shape:
--   { "video_preview_time_ms": 1000 }
-- (see models::media_models::MediaMetadata). Currently only used to record the timestamp
-- MediaRenderer.elm should seek video previews to (via a `#t=` Media Fragments URI on the
-- <video> src) -- absence of the key means "use the browser's default first-frame preview".
ALTER TABLE media ADD COLUMN metadata JSONB NOT NULL DEFAULT '{}';

UPDATE media SET metadata = '{"video_preview_time_ms": 1000}' WHERE content_type LIKE 'video/%';
