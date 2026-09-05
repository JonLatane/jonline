DROP INDEX idx_event_instances_sync_source_unique;

ALTER TABLE event_instances ADD COLUMN sync_source_instance_id VARCHAR;
UPDATE event_instances
SET sync_source_instance_id = sync_source_uid || '|' || (sync_source_recurrence_anchor AT TIME ZONE 'UTC')::text
WHERE sync_source_uid IS NOT NULL AND sync_source_recurrence_anchor IS NOT NULL;
CREATE INDEX idx_event_instances_sync_source_instance_id
  ON event_instances(sync_source_instance_id);

ALTER TABLE event_instances DROP COLUMN sync_source_recurrence_anchor;
ALTER TABLE event_instances DROP COLUMN sync_source_uid;
ALTER TABLE event_instances DROP COLUMN sync_source_id;
