-- This file should undo anything in `up.sql`

DROP TABLE federated_accounts;
DROP TABLE federated_servers;

DROP TABLE event_attendances;
DROP TABLE event_instances;
DROP TABLE events;

DROP TABLE group_posts;
DROP TABLE user_posts;
DROP TABLE posts;

DROP TABLE memberships;
DROP TABLE groups;
ALTER TABLE users DROP CONSTRAINT fk_user_avatar;
DROP TABLE media;

DROP TABLE follows;

DROP TABLE user_access_tokens;
DROP TABLE user_refresh_tokens;
DROP TABLE user_devices;
DROP TABLE users;

DROP TABLE server_configurations;
