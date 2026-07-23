-- Fixes full-text search silently dropping common words like "about": the `english` text search
-- configuration used for posts.title/content and users.bio applies Postgres's built-in English
-- stopword list, so `to_tsvector('english', 'a post about dogs')` never indexes "about" at all -
-- a literal search for "about" can never match. Rather than special-casing English (Postgres has
-- no single built-in "multilingual" stemming config, and this app's content isn't English-only),
-- title/content/bio switch to `simple` - the same config already used for usernames/real
-- names/links below. `simple` just folds case and tokenizes, with no stemming and no per-language
-- stopword list, so it stays correct across languages at the cost of stemming (a search for "run"
-- will no longer also match "running").
CREATE OR REPLACE FUNCTION posts_build_search_text(
  p_title VARCHAR,
  p_link VARCHAR,
  p_content TEXT,
  p_username VARCHAR,
  p_real_name VARCHAR
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_username, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_real_name, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_content, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_link, '')), 'D');
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION users_build_search_text(
  p_username VARCHAR,
  p_real_name VARCHAR,
  p_bio TEXT
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_username, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_real_name, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_bio, '')), 'C');
$$ LANGUAGE sql IMMUTABLE;

-- Recompute posts.search_text (a plain, trigger-maintained column) for all existing rows using
-- the redefined function - same backfill as the original migration.
UPDATE posts
SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, users.username, users.real_name)
FROM users WHERE users.id = posts.user_id;

UPDATE posts
SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, NULL, NULL)
WHERE posts.user_id IS NULL;

-- users.search_text is a `GENERATED ALWAYS AS (...) STORED` column, so it can't be UPDATEd
-- directly. Dropping and re-adding it forces Postgres to recompute it for every existing row
-- from the now-redefined users_build_search_text.
DROP INDEX IF EXISTS idx_users_search_text;
ALTER TABLE users DROP COLUMN search_text;
ALTER TABLE users ADD COLUMN search_text tsvector
  GENERATED ALWAYS AS (users_build_search_text(username, real_name, bio)) STORED;
CREATE INDEX idx_users_search_text ON users USING GIN (search_text);
