DROP INDEX IF EXISTS idx_posts_search_user_context;
DROP TRIGGER IF EXISTS users_search_text_update ON users;
DROP TRIGGER IF EXISTS posts_search_text_update ON posts;
DROP FUNCTION IF EXISTS users_search_text_trigger();
DROP FUNCTION IF EXISTS posts_search_text_trigger();
DROP FUNCTION IF EXISTS posts_build_search_text(VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR);
ALTER TABLE posts DROP COLUMN search_text;
DROP EXTENSION IF EXISTS btree_gin;
