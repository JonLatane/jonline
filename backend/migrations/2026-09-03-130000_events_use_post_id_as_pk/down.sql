-- Structural revert of up.sql. Note this cannot restore the original surrogate id *values* (they
-- were dropped permanently) -- it regenerates fresh BIGSERIAL ids and repoints dependents at
-- those, which is sufficient to restore the pre-migration shape/behavior.

-- 1. Drop the FKs that point at post_id.
ALTER TABLE event_instance_sync_destinations DROP CONSTRAINT event_instance_sync_destinations_event_instance_id_fkey;
ALTER TABLE event_attendances DROP CONSTRAINT event_attendances_event_instance_id_fkey;
ALTER TABLE event_instances DROP CONSTRAINT event_instances_event_id_fkey;
ALTER TABLE event_instances DROP CONSTRAINT event_instances_post_id_fkey;

-- 2. Drop the post_id-based primary keys.
ALTER TABLE events DROP CONSTRAINT events_pkey;
ALTER TABLE event_instances DROP CONSTRAINT event_instances_pkey;

-- 3. Recreate the surrogate id columns/sequences and make them primary keys again.
ALTER TABLE events ADD COLUMN id BIGSERIAL;
ALTER TABLE events ADD PRIMARY KEY (id);

ALTER TABLE event_instances ADD COLUMN id BIGSERIAL;
ALTER TABLE event_instances ADD PRIMARY KEY (id);

-- 4. Recreate the (now non-redundant again) post_id indexes.
CREATE INDEX idx_events_post_id ON events (post_id);
CREATE INDEX idx_event_instances_post_id ON event_instances (post_id);

-- 5. Repoint the FK columns back at the surrogate ids (post_id values are unchanged throughout,
--    so these joins are safe regardless of statement order).
UPDATE event_instances ei
  SET event_id = e.id
  FROM events e
  WHERE ei.event_id = e.post_id;

UPDATE event_attendances ea
  SET event_instance_id = ei.id
  FROM event_instances ei
  WHERE ea.event_instance_id = ei.post_id;

UPDATE event_instance_sync_destinations eisd
  SET event_instance_id = ei.id
  FROM event_instances ei
  WHERE eisd.event_instance_id = ei.post_id;

-- 6. Restore the original FK constraints.
ALTER TABLE event_instances ADD CONSTRAINT event_instances_post_id_fkey
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE SET NULL;

ALTER TABLE event_instances ADD CONSTRAINT event_instances_event_id_fkey
  FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE;

ALTER TABLE event_attendances ADD CONSTRAINT event_attendances_event_instance_id_fkey
  FOREIGN KEY (event_instance_id) REFERENCES event_instances(id) ON DELETE CASCADE;

ALTER TABLE event_instance_sync_destinations ADD CONSTRAINT event_instance_sync_destinations_event_instance_id_fkey
  FOREIGN KEY (event_instance_id) REFERENCES event_instances(id);

-- 7. Restore the original search-text trigger body (looked up the parent Event by surrogate id).
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

-- 8. Restore the original bodies of the two Post/User-edit search_text propagation triggers
--    (they independently joined events by its surrogate id, same as event_instances_search_text_trigger).
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
