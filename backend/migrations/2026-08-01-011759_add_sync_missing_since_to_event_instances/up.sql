-- Tracks when a synced EventInstance first stopped appearing in its EventSyncSource's feed, so a
-- transient/partial upstream response gives the instance (and the Post backing its comment
-- thread/media) a grace period before it's actually deleted -- see event_sync.rs.
ALTER TABLE event_instances ADD COLUMN sync_missing_since TIMESTAMP NULL DEFAULT NULL;
