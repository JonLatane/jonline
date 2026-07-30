-- This file should undo anything in `up.sql`
DROP INDEX idx_event_instances_event_sync_source_instance_id;
ALTER TABLE event_instances DROP COLUMN event_sync_source_instance_id;

DROP INDEX idx_events_event_sync_source_id;
ALTER TABLE events DROP COLUMN event_sync_source_id;

DROP TABLE event_sync_sources;
