-- Width divided by height, populated by bin/convert_media_sizes.rs once it's read the media's
-- dimensions via ImageMagick/ffprobe. NULL until then (and for content types that job doesn't
-- know how to inspect) -- see logic::media_conversion::convert_media.
ALTER TABLE media ADD COLUMN aspect_ratio REAL NULL DEFAULT NULL;
