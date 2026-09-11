ALTER TABLE events ADD COLUMN sync_source_id BIGINT REFERENCES sync_sources(id);
CREATE INDEX idx_events_sync_source_id ON events(sync_source_id);

ALTER TABLE event_instances ADD COLUMN sync_source_id BIGINT REFERENCES sync_sources(id);
ALTER TABLE event_instances ADD COLUMN sync_source_uid VARCHAR;
ALTER TABLE event_instances ADD COLUMN sync_source_recurrence_anchor TIMESTAMP;

UPDATE events e
SET sync_source_id = p.sync_source_id
FROM posts p
WHERE p.id = e.post_id AND p.sync_source_id IS NOT NULL;

UPDATE event_instances ei
SET sync_source_id = p.sync_source_id,
    sync_source_uid = p.sync_source_uid,
    sync_source_recurrence_anchor = p.sync_source_recurrence_anchor
FROM posts p
WHERE p.id = ei.post_id AND p.sync_source_id IS NOT NULL;

CREATE UNIQUE INDEX idx_event_instances_sync_source_unique
  ON event_instances(sync_source_id, sync_source_uid, sync_source_recurrence_anchor)
  WHERE sync_source_id IS NOT NULL;

DROP INDEX idx_posts_sync_source_unique_recurring;
DROP INDEX idx_posts_sync_source_unique_non_recurring;
DROP INDEX idx_posts_sync_source_id;
ALTER TABLE posts DROP COLUMN sync_source_id;
ALTER TABLE posts DROP COLUMN sync_source_uid;
ALTER TABLE posts DROP COLUMN sync_source_recurrence_anchor;
