-- Adds two denormalized per-user counters, mirroring the existing follower_count/following_count/
-- group_count/post_count/response_count/event_count columns:
--   - friend_count: users this user mutually follows (and is followed by).
--   - event_instance_count: EventInstances across all Events this user has created.
--
-- Both are kept mostly-in-sync by application code as their underlying rows change (see
-- backend/src/logic/user_counts.rs), and corrected for any drift by the hourly
-- backend/src/bin/update_user_counts.rs background job.
ALTER TABLE users ADD COLUMN friend_count INT4 NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN event_instance_count INT4 NOT NULL DEFAULT 0;

-- Supporting indexes so both the per-mutation updates and the background job's full recompute
-- can look these counts up per-user without a sequential scan:
--   - follows only had a unique index on (user_id, target_user_id) -- fine for following_count,
--     but follower_count/friend_count both filter by target_user_id.
CREATE INDEX idx_follows_target_user_id ON follows(target_user_id);
--   - event_instances.user_id (denormalized from the instance's own Post's author, see
--     2026-07-30-170000_add_search_text_to_event_instances) only had a GIN index covering
--     (user_id, ends_at, search_text) for search -- a plain btree serves a simple per-user COUNT
--     better.
CREATE INDEX idx_event_instances_user_id ON event_instances(user_id);
--   - posts didn't have any index leading with user_id alone; post_count/response_count/
--     event_count (the last via a join to events) all filter posts by (user_id, context).
CREATE INDEX idx_posts_user_id_context ON posts(user_id, context);
