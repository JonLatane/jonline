-- Adds full-text search over Users: username, real name, and bio.
--
-- Unlike posts.search_text (backend/migrations/2026-07-22-144348_add_search_text_to_posts),
-- every field searched here (username, real_name, bio) lives on the users row itself, so no
-- cross-table denormalization/triggers are needed - a `GENERATED ALWAYS AS ... STORED` column
-- suffices. Postgres requires a generated column's expression to be IMMUTABLE; `to_tsvector`
-- itself is only STABLE (a text search configuration can in principle change), so - mirroring
-- posts_build_search_text's own trick - the tsvector build is wrapped in a small SQL function
-- explicitly declared IMMUTABLE (Postgres trusts the declared volatility of a function it's
-- given, it doesn't recheck what that function calls internally).
CREATE FUNCTION users_build_search_text(
  p_username VARCHAR,
  p_real_name VARCHAR,
  p_bio TEXT
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_username, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_real_name, '')), 'B') ||
    setweight(to_tsvector('english', coalesce(p_bio, '')), 'C');
$$ LANGUAGE sql IMMUTABLE;

ALTER TABLE users ADD COLUMN search_text tsvector
  GENERATED ALWAYS AS (users_build_search_text(username, real_name, bio)) STORED;

-- A plain (non-btree_gin) GIN index: unlike posts' GetPosts TEXT_SEARCH path (which also filters
-- on the plain equality columns user_id/context, hence btree_gin there), GetUsers' listing_type
-- scoping (followers/following/friends/follow_requests) works entirely through joins against
-- `follows`, not a `users`-table equality column, so there's no equality column here worth
-- combining into a composite index.
CREATE INDEX idx_users_search_text ON users USING GIN (search_text);
