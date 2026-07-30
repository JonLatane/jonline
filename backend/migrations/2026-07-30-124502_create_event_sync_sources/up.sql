CREATE TABLE event_sync_sources (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  sync_interval_seconds BIGINT NOT NULL DEFAULT 3600,
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  last_synced_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP
);
CREATE INDEX idx_event_sync_sources_user_id ON event_sync_sources(user_id);

ALTER TABLE events ADD COLUMN event_sync_source_id BIGINT REFERENCES event_sync_sources(id);
CREATE INDEX idx_events_event_sync_source_id ON events(event_sync_source_id);

ALTER TABLE event_instances ADD COLUMN event_sync_source_instance_id VARCHAR;
CREATE INDEX idx_event_instances_event_sync_source_instance_id ON event_instances(event_sync_source_instance_id);
