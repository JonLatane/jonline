-- This file should undo anything in `up.sql`
ALTER TABLE posts DROP COLUMN user_id;
ALTER TABLE posts DROP COLUMN parent_post_id;
DROP TABLE user_refresh_tokens;
DROP TABLE user_auth_tokens;
DROP TABLE users;