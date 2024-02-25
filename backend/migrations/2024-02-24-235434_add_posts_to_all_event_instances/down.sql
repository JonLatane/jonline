-- This file should undo anything in `up.sql`

ALTER TABLE event_instances ALTER COLUMN post_id DROP NOT NULL;
DELETE FROM posts WHERE context = 'EVENT_INSTANCE';
