DROP INDEX idx_posts_user_id_context;
DROP INDEX idx_event_instances_user_id;
DROP INDEX idx_follows_target_user_id;

ALTER TABLE users DROP COLUMN event_instance_count;
ALTER TABLE users DROP COLUMN friend_count;
