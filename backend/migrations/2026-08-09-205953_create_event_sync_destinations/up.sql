CREATE TABLE event_sync_destinations (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  configuration JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP
);
CREATE INDEX idx_event_sync_destinations_user_id ON event_sync_destinations(user_id);

CREATE TABLE event_instance_sync_destinations (
  event_instance_id BIGINT NOT NULL REFERENCES event_instances(id),
  event_sync_destination_id BIGINT NOT NULL REFERENCES event_sync_destinations(id),
  destination_instance_id VARCHAR,
  destination_url VARCHAR,
  synced_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (event_instance_id, event_sync_destination_id)
);
CREATE INDEX idx_event_instance_sync_destinations_destination_id ON event_instance_sync_destinations(event_sync_destination_id);
