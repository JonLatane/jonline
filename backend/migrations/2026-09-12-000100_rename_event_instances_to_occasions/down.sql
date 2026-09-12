-- This file should undo anything in `up.sql`
DROP TRIGGER users_propagate_search_text_to_occasions_update ON users;
DROP FUNCTION users_propagate_search_text_to_occasions();

DROP TRIGGER posts_propagate_search_text_to_occasions_update ON posts;
DROP FUNCTION posts_propagate_search_text_to_occasions();

DROP TRIGGER occasions_search_text_update ON occasions;
DROP FUNCTION occasions_search_text_trigger();
DROP FUNCTION occasions_build_search_text(varchar, text, varchar, varchar, text, varchar, text, varchar, varchar);

ALTER TABLE occasions RENAME TO event_instances;
ALTER INDEX idx_occasions_user_id RENAME TO idx_event_instances_user_id;
ALTER INDEX idx_occasions_search_user_ends_at RENAME TO idx_event_instances_search_user_ends_at;
ALTER INDEX idx_occasions_event_id RENAME TO idx_event_instances_event_id;
ALTER INDEX idx_occasion_starts_at RENAME TO idx_event_instance_starts_at;
ALTER INDEX idx_occasion_ends_at RENAME TO idx_event_instance_ends_at;
ALTER TABLE event_instances RENAME CONSTRAINT occasions_post_id_fkey TO event_instances_post_id_fkey;
ALTER TABLE event_instances RENAME CONSTRAINT occasions_event_id_fkey TO event_instances_event_id_fkey;
ALTER TABLE event_instances RENAME CONSTRAINT occasions_pkey TO event_instances_pkey;

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
    WHERE events.post_id = NEW.event_id;

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
  BEFORE INSERT OR UPDATE OF post_id, event_id ON event_instances
  FOR EACH ROW EXECUTE FUNCTION event_instances_search_text_trigger();

CREATE FUNCTION posts_propagate_search_text_to_event_instances() RETURNS trigger AS $$
BEGIN
  IF NEW.title IS DISTINCT FROM OLD.title
    OR NEW.content IS DISTINCT FROM OLD.content
    OR NEW.user_id IS DISTINCT FROM OLD.user_id THEN

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
      AND ei.event_id = ev.post_id
      AND ev.post_id = event_post.id;

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
      AND ei.event_id = ev.post_id
      AND ei.post_id = instance_post.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER posts_propagate_search_text_to_event_instances_update
  AFTER UPDATE OF title, content, user_id ON posts
  FOR EACH ROW EXECUTE FUNCTION posts_propagate_search_text_to_event_instances();

CREATE FUNCTION users_propagate_search_text_to_event_instances() RETURNS trigger AS $$
BEGIN
  IF NEW.username IS DISTINCT FROM OLD.username OR NEW.real_name IS DISTINCT FROM OLD.real_name THEN
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
      AND ei.event_id = ev.post_id
      AND ev.post_id = event_post.id;

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
      AND ei.event_id = ev.post_id
      AND ev.post_id = event_post.id
      AND event_post.user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_propagate_search_text_to_event_instances_update
  AFTER UPDATE OF username, real_name ON users
  FOR EACH ROW EXECUTE FUNCTION users_propagate_search_text_to_event_instances();

ALTER TABLE users RENAME COLUMN occasion_count TO event_instance_count;
ALTER TABLE sync_sources RENAME COLUMN occasion_count TO event_instance_count;

ALTER TABLE occasion_sync_destinations RENAME TO event_instance_sync_destinations;
ALTER TABLE event_instance_sync_destinations RENAME COLUMN occasion_id TO event_instance_id;
ALTER INDEX idx_occasion_sync_destinations_sync_destination_id RENAME TO idx_event_instance_sync_destinations_sync_destination_id;
ALTER TABLE event_instance_sync_destinations RENAME CONSTRAINT occasion_sync_destinations_sync_destination_id_fkey TO event_instance_sync_destinations_event_sync_destination_id_fkey;
ALTER TABLE event_instance_sync_destinations RENAME CONSTRAINT occasion_sync_destinations_occasion_id_fkey TO event_instance_sync_destinations_event_instance_id_fkey;
ALTER TABLE event_instance_sync_destinations RENAME CONSTRAINT occasion_sync_destinations_pkey TO event_instance_sync_destinations_pkey;

ALTER TABLE event_attendances RENAME COLUMN occasion_id TO event_instance_id;
ALTER TABLE event_attendances RENAME CONSTRAINT event_attendances_occasion_id_fkey TO event_attendances_event_instance_id_fkey;
