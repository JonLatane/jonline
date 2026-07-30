-- Adds the EventInstance's own location (event_instances.location->>'uniformly_formatted_address')
-- to the search text built by 2026-07-30-170000_add_search_text_to_event_instances -- e.g.
-- searching "Central Park" should find instances held there even if neither the instance's nor
-- its parent Event's Post title/content mentions the location by name.
--
-- `location` is a JSONB column storing a serialized `Location` proto (see
-- backend/src/logic/event_sync.rs's `location_json` and protos/location.proto) -- the only field
-- worth indexing off it is `uniformly_formatted_address` (`id`/`creator_id` aren't
-- human-searchable text). Only event_instances has a `location` column -- events does not -- so
-- unlike title/content/username/real_name there's no separate "event's location" to also fold in.
--
-- Weighted 'B', alongside real_name/content: like content, it's descriptive/supplementary text
-- rather than a primary identifying field like title/username (weight 'A').
--
-- event_instances_build_search_text needs a new parameter, so (per Postgres rules) it must be
-- dropped and recreated rather than CREATE OR REPLACE'd -- the trigger/propagation functions that
-- call it are simple CREATE OR REPLACE, and event_instances_search_text_trigger's own trigger is
-- dropped/recreated to additionally fire on UPDATE OF location (NEW.location is only visible to a
-- BEFORE trigger already listening for that column).
DROP TRIGGER IF EXISTS event_instances_search_text_update ON event_instances;
DROP FUNCTION event_instances_build_search_text(VARCHAR, TEXT, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR);

CREATE FUNCTION event_instances_build_search_text(
  p_instance_title VARCHAR,
  p_instance_content TEXT,
  p_instance_username VARCHAR,
  p_instance_real_name VARCHAR,
  p_instance_location TEXT,
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
    setweight(to_tsvector('simple', coalesce(p_instance_location, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_event_real_name, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_event_content, '')), 'B');
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION event_instances_search_text_trigger() RETURNS trigger AS $$
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
    NEW.location->>'uniformly_formatted_address',
    v_event_title, v_event_content, v_event_username, v_event_real_name
  );
  NEW.user_id := v_instance_user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_instances_search_text_update
  BEFORE INSERT OR UPDATE OF post_id, event_id, location ON event_instances
  FOR EACH ROW EXECUTE FUNCTION event_instances_search_text_trigger();

-- Both propagation functions below update event_instances rows (aliased `ei`) from an UPDATE ...
-- FROM, so -- same rule as the parent migration -- `ei.location` may be read directly since it's
-- only ever referenced in the SET clause/WHERE, never inside a FROM-list JOIN ON.
CREATE OR REPLACE FUNCTION posts_propagate_search_text_to_event_instances() RETURNS trigger AS $$
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
          ei.location->>'uniformly_formatted_address',
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
          ei.location->>'uniformly_formatted_address',
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

CREATE OR REPLACE FUNCTION users_propagate_search_text_to_event_instances() RETURNS trigger AS $$
BEGIN
  IF NEW.username IS DISTINCT FROM OLD.username OR NEW.real_name IS DISTINCT FROM OLD.real_name THEN
    -- NEW authored an EventInstance's own Post.
    UPDATE event_instances ei
    SET search_text = event_instances_build_search_text(
          instance_post.title, instance_post.content, NEW.username, NEW.real_name,
          ei.location->>'uniformly_formatted_address',
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
          ei.location->>'uniformly_formatted_address',
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

-- Backfill existing rows so already-synced instances pick up their location immediately, rather
-- than waiting on the next edit/sync to re-trigger.
UPDATE event_instances ei
SET search_text = event_instances_build_search_text(
      instance_post.title, instance_post.content,
      (SELECT username FROM users WHERE id = instance_post.user_id),
      (SELECT real_name FROM users WHERE id = instance_post.user_id),
      ei.location->>'uniformly_formatted_address',
      event_post.title, event_post.content,
      (SELECT username FROM users WHERE id = event_post.user_id),
      (SELECT real_name FROM users WHERE id = event_post.user_id)
    )
FROM posts instance_post, events ev, posts event_post
WHERE ei.post_id = instance_post.id
  AND ei.event_id = ev.id
  AND ev.post_id = event_post.id;
