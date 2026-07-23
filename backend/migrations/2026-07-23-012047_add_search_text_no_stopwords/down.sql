CREATE OR REPLACE FUNCTION posts_build_search_text(
  p_title VARCHAR,
  p_link VARCHAR,
  p_content TEXT,
  p_username VARCHAR,
  p_real_name VARCHAR
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_username, '')), 'A') ||
    setweight(to_tsvector('english', coalesce(p_title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_real_name, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(p_content, '')), 'B') ||
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
    setweight(to_tsvector('english', coalesce(p_bio, '')), 'C');
$$ LANGUAGE sql IMMUTABLE;

UPDATE posts
SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, users.username, users.real_name)
FROM users WHERE users.id = posts.user_id;

UPDATE posts
SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, NULL, NULL)
WHERE posts.user_id IS NULL;

DROP INDEX IF EXISTS idx_users_search_text;
ALTER TABLE users DROP COLUMN search_text;
ALTER TABLE users ADD COLUMN search_text tsvector
  GENERATED ALWAYS AS (users_build_search_text(username, real_name, bio)) STORED;
CREATE INDEX idx_users_search_text ON users USING GIN (search_text);
