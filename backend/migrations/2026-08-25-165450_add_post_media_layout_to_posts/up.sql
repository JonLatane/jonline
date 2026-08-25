CREATE TYPE post_media_layout AS ENUM ('media_layout_standard', 'media_layout_dynamic_vertical_scroll');

ALTER TABLE posts ADD COLUMN post_media_layout post_media_layout NOT NULL DEFAULT 'media_layout_standard';
