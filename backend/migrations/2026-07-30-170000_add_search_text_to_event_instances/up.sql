-- Adds full-text search over EventInstances: the title/content/author username/author real name
-- of BOTH the EventInstance's own Post and its parent Event's Post -- e.g. searching "farmers
-- market" should find a recurring "Farmers Market" Event's one-off "Farmers Market" EventInstance
-- even if the instance's own Post has no title/content of its own (the common case -- most
-- instances don't override their parent Event's title/content, see `Components.Events.meaningfulPost`).
--
-- Mirrors posts.search_text (backend/migrations/2026-07-22-144348_add_search_text_to_posts) --
-- same tsvector-column-plus-triggers denormalization strategy, same "simple" (not "english")
-- config (see 2026-07-23-012047_add_search_text_no_stopwords for why) -- just spanning four
-- tables instead of two: event_instances + its own posts/users, and events + *its* posts/users.
--
-- Also denormalizes event_instances.user_id from the instance's own Post's author. This isn't
-- used for visibility (query_visible_events! still does that via real joins) -- it exists purely
-- so a composite GIN index can cover an author-scoped search
-- (`{listing_type: EVENT_TEXT_SEARCH, author_user_id:, search_text:}`, e.g. searching within one
-- user's own events page) in a single index scan, the same way posts.user_id already does for
-- idx_posts_search_user_context. In this codebase an EventInstance's own Post and its parent
-- Event's Post are always authored by the same user (both are set to the creating/syncing user at
-- creation time -- see create_event.rs/update_event.rs/event_sync.rs), so the instance's own
-- author is an equally valid (and simpler to maintain -- one join, not two) stand-in for "the
-- event's author" that get_user_events itself filters by.
--
-- The propagation UPDATEs below all use scalar subqueries for the "look up a user's
-- username/real_name" step, and only ever join *other* FROM-list tables to each other (never to
-- the `event_instances` target row) inside a `JOIN ... ON` - Postgres rejects an UPDATE ... FROM
-- whose FROM-list JOIN conditions reference the target table (confirmed while writing this
-- migration: "invalid reference to FROM-clause entry for table"). Every correlation back to the
-- target row instead lives in the UPDATE's WHERE clause, which - unlike a nested JOIN ON - is
-- always allowed to reference both the target table and every FROM-list table.
CREATE EXTENSION IF NOT EXISTS btree_gin;

ALTER TABLE event_instances ADD COLUMN search_text tsvector NOT NULL DEFAULT ''::tsvector;
ALTER TABLE event_instances ADD COLUMN user_id BIGINT;

CREATE FUNCTION event_instances_build_search_text(
  p_instance_title VARCHAR,
  p_instance_content TEXT,
  p_instance_username VARCHAR,
  p_instance_real_name VARCHAR,
  p_event_title VARCHAR,
  p_event_content TEXT,
  p_event_username VARCHAR,
  p_event_real_name VARCHAR
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_instance_username, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_instance_title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_event_username, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_event_title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_instance_real_name, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_instance_content, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_event_real_name, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_event_content, '')), 'B');
$$ LANGUAGE sql IMMUTABLE;

-- Recomputes NEW's search_text/user_id from scratch by looking up both Posts (+ their authors)
-- fresh. Fires on insert, and on update of post_id/event_id (the only columns that change which
-- rows those lookups touch) -- mirrors posts_search_text_trigger firing on update of
-- title/link/content/user_id for the same reason.
CREATE FUNCTION event_instances_search_text_trigger() RETURNS trigger AS $$
DECLARE
  v_instance_title VARCHAR;
  v_instance_content TEXT;
  v_instance_user_id BIGINT;
  v_instance_username VARCHAR;
  v_instance_real_name VARCHAR;
  v_event_title VARCHAR;
  v_event_content TEXT;
  v_event_username VARCHAR;
  v_event_real_name VARCHAR;
BEGIN
  SELECT posts.title, posts.content, posts.user_id, users.username, users.real_name
    INTO v_instance_title, v_instance_content, v_instance_user_id, v_instance_username, v_instance_real_name
    FROM posts LEFT JOIN users ON users.id = posts.user_id
    WHERE posts.id = NEW.post_id;

  SELECT posts.title, posts.content, users.username, users.real_name
    INTO v_event_title, v_event_content, v_event_username, v_event_real_name
    FROM events
    JOIN posts ON posts.id = events.post_id
    LEFT JOIN users ON users.id = posts.user_id
    WHERE events.id = NEW.event_id;

  NEW.search_text := event_instances_build_search_text(
    v_instance_title, v_instance_content, v_instance_username, v_instance_real_name,
    v_event_title, v_event_content, v_event_username, v_event_real_name
  );
  NEW.user_id := v_instance_user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_instances_search_text_update
  BEFORE INSERT OR UPDATE OF post_id, event_id ON event_instances
  FOR EACH ROW EXECUTE FUNCTION event_instances_search_text_trigger();

-- Propagates a Post edit into every EventInstance whose search_text/user_id was built from it --
-- either because it's that EventInstance's own Post, or because it's the Post of that
-- EventInstance's parent Event. (A Post can in principle be both at once across different
-- instances, so both UPDATEs below always run; each is a no-op where it matches nothing.) Mirrors
-- users_search_text_trigger's "push the edit to every dependent row" shape.
CREATE FUNCTION posts_propagate_search_text_to_event_instances() RETURNS trigger AS $$
BEGIN
  IF NEW.title IS DISTINCT FROM OLD.title
    OR NEW.content IS DISTINCT FROM OLD.content
    OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN

    -- NEW is directly an EventInstance's own Post.
    UPDATE event_instances ei
    SET search_text = event_instances_build_search_text(
          NEW.title, NEW.content,
          (SELECT username FROM users WHERE id = NEW.user_id),
          (SELECT real_name FROM users WHERE id = NEW.user_id),
          event_post.title, event_post.content,
          (SELECT username FROM users WHERE id = event_post.user_id),
          (SELECT real_name FROM users WHERE id = event_post.user_id)
        ),
        user_id = NEW.user_id
    FROM events ev, posts event_post
    WHERE ei.post_id = NEW.id
      AND ei.event_id = ev.id
      AND ev.post_id = event_post.id;

    -- NEW is a parent Event's Post -- update every EventInstance under that Event.
    UPDATE event_instances ei
    SET search_text = event_instances_build_search_text(
          instance_post.title, instance_post.content,
          (SELECT username FROM users WHERE id = instance_post.user_id),
          (SELECT real_name FROM users WHERE id = instance_post.user_id),
          NEW.title, NEW.content,
          (SELECT username FROM users WHERE id = NEW.user_id),
          (SELECT real_name FROM users WHERE id = NEW.user_id)
        )
    FROM events ev, posts instance_post
    WHERE ev.post_id = NEW.id
      AND ei.event_id = ev.id
      AND ei.post_id = instance_post.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER posts_propagate_search_text_to_event_instances_update
  AFTER UPDATE OF title, content, user_id ON posts
  FOR EACH ROW EXECUTE FUNCTION posts_propagate_search_text_to_event_instances();

-- Propagates a User's username/real_name edit the same way posts_search_text_trigger's sibling
-- users_search_text_trigger does for posts.search_text -- just via two paths (instance-post
-- author, event-post author) instead of one.
CREATE FUNCTION users_propagate_search_text_to_event_instances() RETURNS trigger AS $$
BEGIN
  IF NEW.username IS DISTINCT FROM OLD.username OR NEW.real_name IS DISTINCT FROM OLD.real_name THEN
    -- NEW authored an EventInstance's own Post.
    UPDATE event_instances ei
    SET search_text = event_instances_build_search_text(
          instance_post.title, instance_post.content, NEW.username, NEW.real_name,
          event_post.title, event_post.content,
          (SELECT username FROM users WHERE id = event_post.user_id),
          (SELECT real_name FROM users WHERE id = event_post.user_id)
        )
    FROM posts instance_post, events ev, posts event_post
    WHERE ei.post_id = instance_post.id
      AND instance_post.user_id = NEW.id
      AND ei.event_id = ev.id
      AND ev.post_id = event_post.id;

    -- NEW authored a parent Event's Post.
    UPDATE event_instances ei
    SET search_text = event_instances_build_search_text(
          instance_post.title, instance_post.content,
          (SELECT username FROM users WHERE id = instance_post.user_id),
          (SELECT real_name FROM users WHERE id = instance_post.user_id),
          event_post.title, event_post.content, NEW.username, NEW.real_name
        )
    FROM posts instance_post, events ev, posts event_post
    WHERE ei.post_id = instance_post.id
      AND ei.event_id = ev.id
      AND ev.post_id = event_post.id
      AND event_post.user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_propagate_search_text_to_event_instances_update
  AFTER UPDATE OF username, real_name ON users
  FOR EACH ROW EXECUTE FUNCTION users_propagate_search_text_to_event_instances();

-- Backfill existing rows by re-running the same lookup the insert/update trigger does, driven
-- straight off event_instances/events/posts/users rather than re-triggering row by row.
UPDATE event_instances ei
SET search_text = event_instances_build_search_text(
      instance_post.title, instance_post.content,
      (SELECT username FROM users WHERE id = instance_post.user_id),
      (SELECT real_name FROM users WHERE id = instance_post.user_id),
      event_post.title, event_post.content,
      (SELECT username FROM users WHERE id = event_post.user_id),
      (SELECT real_name FROM users WHERE id = event_post.user_id)
    ),
    user_id = instance_post.user_id
FROM posts instance_post, events ev, posts event_post
WHERE ei.post_id = instance_post.id
  AND ei.event_id = ev.id
  AND ev.post_id = event_post.id;

-- A single composite GIN index (via btree_gin), mirroring idx_posts_search_user_context: since a
-- multicolumn GIN index isn't limited to a leftmost-prefix match, this covers every (ends_at,
-- search_text) and (user_id, ends_at, search_text) lookup GetEvents' EVENT_TEXT_SEARCH path
-- performs (the former for a plain search still scoped by the current time-filter tab, the latter
-- when additionally scoped to one author, e.g. a user's own events page) in one index scan.
CREATE INDEX idx_event_instances_search_user_ends_at ON event_instances USING GIN (user_id, ends_at, search_text);
