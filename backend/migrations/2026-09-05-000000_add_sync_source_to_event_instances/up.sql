-- Denormalizes the SyncSource relationship down onto event_instances (in addition to staying on
-- events, still used by DeleteSyncSource's detach/delete path) and replaces two fragile,
-- app-level-only mechanisms with real, indexed columns -- see
-- `logic::sync_sources::event_sync`'s module doc comment for why that matters (it's what let a
-- plain code rename silently orphan every pre-existing synced Event in the 2026-09-04
-- duplicate-events incident):
--
-- 1. `events.info->>'sync_source_uid'` (a JSON key inside a JSONB blob) -> `sync_source_uid`, a
--    real column, on `event_instances`.
-- 2. `sync_source_instance_id` (a `"{uid}|{recurrence_anchor}"` string, built and parsed by hand
--    in Rust) -> split into `sync_source_uid` (above) plus `sync_source_recurrence_anchor`, a
--    real `Timestamp` column holding just the anchor half: the occurrence's stable identity
--    within its series (its own start time for a plain expansion, or its *original* scheduled
--    time -- iCal's `RECURRENCE-ID` -- for an occurrence that's since been rescheduled, which is
--    deliberately different from that row's own `starts_at` once moved).
ALTER TABLE event_instances ADD COLUMN sync_source_id BIGINT REFERENCES sync_sources(id);
ALTER TABLE event_instances ADD COLUMN sync_source_uid VARCHAR;
ALTER TABLE event_instances ADD COLUMN sync_source_recurrence_anchor TIMESTAMP;

-- COALESCEs the old (pre-2026-09-04-rename) `event_sync_source_uid` JSON key too, in case this
-- runs against a deployment that never had `fix_duplicate_synced_events` run against it.
UPDATE event_instances ei
SET sync_source_id = e.sync_source_id,
    sync_source_uid = COALESCE(e.info ->> 'sync_source_uid', e.info ->> 'event_sync_source_uid'),
    sync_source_recurrence_anchor =
      (split_part(ei.sync_source_instance_id, '|', 2)::timestamptz AT TIME ZONE 'UTC')
FROM events e
WHERE e.post_id = ei.event_id
  AND e.sync_source_id IS NOT NULL
  AND ei.sync_source_instance_id IS NOT NULL;

-- Drops idx_event_instances_sync_source_instance_id along with it.
ALTER TABLE event_instances DROP COLUMN sync_source_instance_id;

-- Hard DB-level guarantee against ever re-creating a duplicate occurrence: this is what actually
-- would have stopped the 2026-09-04 incident (a loud constraint-violation error instead of 19
-- silently-created duplicate Events).
CREATE UNIQUE INDEX idx_event_instances_sync_source_unique
  ON event_instances(sync_source_id, sync_source_uid, sync_source_recurrence_anchor)
  WHERE sync_source_id IS NOT NULL;
