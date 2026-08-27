CREATE TABLE post_sync_destinations (
  post_id BIGINT NOT NULL REFERENCES posts(id),
  sync_destination_id BIGINT NOT NULL REFERENCES sync_destinations(id),
  destination_instance_id VARCHAR,
  destination_url VARCHAR,
  synced_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (post_id, sync_destination_id)
);
CREATE INDEX idx_post_sync_destinations_sync_destination_id ON post_sync_destinations(sync_destination_id);
