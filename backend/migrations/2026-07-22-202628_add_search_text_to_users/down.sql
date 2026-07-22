DROP INDEX IF EXISTS idx_users_search_text;
ALTER TABLE users DROP COLUMN search_text;
DROP FUNCTION IF EXISTS users_build_search_text(VARCHAR, VARCHAR, TEXT);
