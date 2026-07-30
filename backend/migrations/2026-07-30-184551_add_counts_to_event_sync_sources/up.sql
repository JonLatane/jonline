ALTER TABLE event_sync_sources ADD COLUMN event_count BIGINT NOT NULL DEFAULT 0;
ALTER TABLE event_sync_sources ADD COLUMN event_instance_count BIGINT NOT NULL DEFAULT 0;
