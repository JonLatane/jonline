-- Denormalizes SyncSource identity down onto `posts` itself -- previously split across `events`
-- (`sync_source_id` only) and `event_instances` (`sync_source_id`/`sync_source_uid`/
-- `sync_source_recurrence_anchor`, added by 2026-09-05-000000_add_sync_source_to_event_instances).
-- The goal is to let *any* Post be sync-sourced (not just Events/EventInstances), for upcoming
-- RSS/Atom SyncSources that create plain Posts directly (see `sync_sources.post_count`, unused
-- until now).
--
-- `events`/`event_instances` are true 1:1 extension tables of `posts` (`post_id` is their own
-- primary key, FK'd `ON DELETE CASCADE` back to `posts.id` -- see
-- 2026-09-03-130000_events_use_post_id_as_pk), so this is a plain denormalize-up: every Event and
-- EventInstance already has exactly one Post to carry these columns instead.
ALTER TABLE posts ADD COLUMN sync_source_id BIGINT REFERENCES sync_sources(id);
ALTER TABLE posts ADD COLUMN sync_source_uid VARCHAR;
ALTER TABLE posts ADD COLUMN sync_source_recurrence_anchor TIMESTAMP;

-- Events: only `sync_source_id` (no per-item uid at that level pre-migration), but stamp
-- `sync_source_uid` too now that there's a real per-Post column for it, from whichever of that
-- Event's instances carries the series' own uid -- makes an Event's own Post independently
-- findable/unique by (sync_source_id, sync_source_uid) same as everything else. Only in effect
-- for still-synced Events (an already-detached Event has `sync_source_id IS NULL` and gets none of
-- this, matching the pre-migration behavior of `delete_sync_source`'s detach path).
UPDATE posts p
SET sync_source_id = e.sync_source_id,
    sync_source_uid = series_uid.uid
FROM events e
LEFT JOIN LATERAL (
  SELECT ei.sync_source_uid AS uid
  FROM event_instances ei
  WHERE ei.event_id = e.post_id AND ei.sync_source_uid IS NOT NULL
  LIMIT 1
) series_uid ON true
WHERE e.post_id = p.id
  AND e.sync_source_id IS NOT NULL;

-- EventInstances: straight copy, one row each.
UPDATE posts p
SET sync_source_id = ei.sync_source_id,
    sync_source_uid = ei.sync_source_uid,
    sync_source_recurrence_anchor = ei.sync_source_recurrence_anchor
FROM event_instances ei
WHERE ei.post_id = p.id
  AND ei.sync_source_id IS NOT NULL;

CREATE INDEX idx_posts_sync_source_id ON posts(sync_source_id);

-- Two partial unique indexes, not one across all three columns: Postgres unique indexes treat
-- NULL as never colliding (two rows can both have `sync_source_recurrence_anchor IS NULL` without
-- violating a unique index that includes it), and `sync_source_recurrence_anchor` is NULL for
-- everything that isn't a recurring EventInstance occurrence -- a plain synced Post (RSS/Atom) or
-- an Event's own series-level Post included. A single three-column index would silently stop
-- enforcing uniqueness for exactly those rows -- the same class of bug the 2026-09-04
-- duplicate-events incident was about (see `logic::sync_sources::event_sync`'s module doc).
CREATE UNIQUE INDEX idx_posts_sync_source_unique_recurring
  ON posts(sync_source_id, sync_source_uid, sync_source_recurrence_anchor)
  WHERE sync_source_id IS NOT NULL AND sync_source_recurrence_anchor IS NOT NULL;

CREATE UNIQUE INDEX idx_posts_sync_source_unique_non_recurring
  ON posts(sync_source_id, sync_source_uid)
  WHERE sync_source_id IS NOT NULL AND sync_source_recurrence_anchor IS NULL;

DROP INDEX idx_event_instances_sync_source_unique;
ALTER TABLE event_instances DROP COLUMN sync_source_id;
ALTER TABLE event_instances DROP COLUMN sync_source_uid;
ALTER TABLE event_instances DROP COLUMN sync_source_recurrence_anchor;

DROP INDEX idx_events_sync_source_id;
ALTER TABLE events DROP COLUMN sync_source_id;
