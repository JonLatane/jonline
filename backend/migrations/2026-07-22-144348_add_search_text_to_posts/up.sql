-- Adds full-text search over Posts: author username, author real name, title, link, and content.
--
-- Postgres tsvector/tsquery (built-in text search) is used. Since the searchable text spans two
-- tables (posts + users), a single tsvector can't be a `GENERATED ALWAYS AS ... STORED` column
-- (those can only reference their own row). Instead, `posts.search_text` is a denormalized tsvector
-- kept in sync by triggers:
--   - on posts insert/update of title/link/content/user_id, recompute from the row + its author
--   - on users update of username/real_name, recompute search_text for all of that user's posts
--
-- btree_gin (standard bundled Postgres contrib module) lets a single GIN index combine the
-- tsvector column with the plain equality columns (context, user_id) queries filter by, so
-- lookups by (context, search_text), (user_id, search_text), and (user_id, context, search_text)
-- each hit one index scan instead of an index scan plus a table-side filter.
CREATE EXTENSION IF NOT EXISTS btree_gin;

ALTER TABLE posts ADD COLUMN search_text tsvector NOT NULL DEFAULT ''::tsvector;

CREATE FUNCTION posts_build_search_text(
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

CREATE FUNCTION posts_search_text_trigger() RETURNS trigger AS $$
DECLARE
  v_username VARCHAR;
  v_real_name VARCHAR;
BEGIN
  IF NEW.user_id IS NOT NULL THEN
    SELECT username, real_name INTO v_username, v_real_name FROM users WHERE id = NEW.user_id;
  END IF;
  NEW.search_text := posts_build_search_text(NEW.title, NEW.link, NEW.content, v_username, v_real_name);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER posts_search_text_update
  BEFORE INSERT OR UPDATE OF title, link, content, user_id ON posts
  FOR EACH ROW EXECUTE FUNCTION posts_search_text_trigger();

CREATE FUNCTION users_search_text_trigger() RETURNS trigger AS $$
BEGIN
  IF NEW.username IS DISTINCT FROM OLD.username OR NEW.real_name IS DISTINCT FROM OLD.real_name THEN
    UPDATE posts
    SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, NEW.username, NEW.real_name)
    WHERE posts.user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_search_text_update
  AFTER UPDATE OF username, real_name ON users
  FOR EACH ROW EXECUTE FUNCTION users_search_text_trigger();

-- Backfill existing rows.
UPDATE posts
SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, users.username, users.real_name)
FROM users WHERE users.id = posts.user_id;

UPDATE posts
SET search_text = posts_build_search_text(posts.title, posts.link, posts.content, NULL, NULL)
WHERE posts.user_id IS NULL;

-- A single composite GIN index (via btree_gin) covers every (context, search_text), (user_id,
-- search_text), and (user_id, context, search_text) lookup the GetPosts TEXT_SEARCH RPC path
-- performs. Unlike a btree, a multicolumn GIN index isn't limited to a leftmost-prefix match -
-- each indexed column contributes independent postings that get combined at scan time, so a
-- query naming any subset of (user_id, context, search_text) - confirmed with EXPLAIN - hits this
-- one index. Separate (context, search_text) and (user_id, search_text) indexes would be pure
-- dead weight alongside this one.
CREATE INDEX idx_posts_search_user_context ON posts USING GIN (user_id, context, search_text);
