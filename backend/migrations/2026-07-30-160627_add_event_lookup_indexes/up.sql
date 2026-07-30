-- get_events (and event_loaders/event_sync/delete_group_post) constantly join event_instances to
-- events on event_id, and events/event_instances to posts on post_id -- e.g. the events::id.eq(..)
-- lookup in get_event_by_id, get_event_instances (called on every single-event fetch), and the
-- events::post_id/event_instances::post_id lookups in get_event_by_post_id and
-- delete_group_post. None of these columns had an index, forcing a sequential scan of
-- event_instances/events for what should be a single-row lookup.
CREATE INDEX idx_event_instances_event_id ON event_instances(event_id);
CREATE INDEX idx_event_instances_post_id ON event_instances(post_id);
CREATE INDEX idx_events_post_id ON events(post_id);
