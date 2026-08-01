-- This file should undo anything in `up.sql`
ALTER TABLE event_instances DROP COLUMN sync_missing_since;
