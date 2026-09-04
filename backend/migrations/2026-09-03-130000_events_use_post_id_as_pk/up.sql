-- events.id and event_instances.id are redundant surrogate keys: both tables already carry a
-- required, unique post_id (every Event/EventInstance is 1:1 with its own Post). This drops the
-- surrogates and makes post_id the primary key for both tables, repointing every FK that used to
-- reference the surrogate id to reference post_id instead.

-- 1. Drop the FK constraints that reference the surrogate ids so their columns can be freely
--    rewritten below without transient FK violations.
ALTER TABLE event_instances DROP CONSTRAINT event_instances_event_id_fkey;
ALTER TABLE event_attendances DROP CONSTRAINT event_attendances_event_instance_id_fkey;
ALTER TABLE event_instance_sync_destinations DROP CONSTRAINT event_instance_sync_destinations_event_instance_id_fkey;

-- 2. Rewrite each FK column in place to hold the target row's post_id instead of its surrogate id.
--    These joins read events/event_instances' original (still-intact) id columns, so they're safe
--    as single atomic statements regardless of statement order.
UPDATE event_instances ei
  SET event_id = e.post_id
  FROM events e
  WHERE ei.event_id = e.id;

UPDATE event_attendances ea
  SET event_instance_id = ei.post_id
  FROM event_instances ei
  WHERE ea.event_instance_id = ei.id;

UPDATE event_instance_sync_destinations eisd
  SET event_instance_id = ei.post_id
  FROM event_instances ei
  WHERE eisd.event_instance_id = ei.id;

-- 3. Drop the now-redundant non-unique indexes on post_id (the new PRIMARY KEY below creates its
--    own unique index covering the same column).
DROP INDEX idx_events_post_id;
DROP INDEX idx_event_instances_post_id;

-- 4. Drop the surrogate id columns (this also drops their owned sequences and PK constraints) and
--    promote post_id to primary key.
ALTER TABLE events DROP COLUMN id;
ALTER TABLE events ADD PRIMARY KEY (post_id);

ALTER TABLE event_instances DROP COLUMN id;
ALTER TABLE event_instances ADD PRIMARY KEY (post_id);

-- 5. Re-add the FKs, now pointing at post_id. event_instances.post_id's FK becomes ON DELETE
--    CASCADE (it must -- a primary key column can never be set NULL; the old "ON DELETE SET NULL"
--    was already dead code, since post_id has always been NOT NULL).
ALTER TABLE event_instances DROP CONSTRAINT event_instances_post_id_fkey;
ALTER TABLE event_instances ADD CONSTRAINT event_instances_post_id_fkey
  FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE;

ALTER TABLE event_instances ADD CONSTRAINT event_instances_event_id_fkey
  FOREIGN KEY (event_id) REFERENCES events(post_id) ON DELETE CASCADE;

ALTER TABLE event_attendances ADD CONSTRAINT event_attendances_event_instance_id_fkey
  FOREIGN KEY (event_instance_id) REFERENCES event_instances(post_id) ON DELETE CASCADE;

ALTER TABLE event_instance_sync_destinations ADD CONSTRAINT event_instance_sync_destinations_event_instance_id_fkey
  FOREIGN KEY (event_instance_id) REFERENCES event_instances(post_id);

-- 6. event_instances_search_text_trigger looked up the parent Event by "events.id = NEW.event_id";
--    repoint it at events.post_id, which is what NEW.event_id now holds.
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

-- 7. Two more triggers ("propagate a Post edit's title/content/author into any EventInstance
--    search_text that depends on it") independently join events by its old surrogate id --
--    repoint them at events.post_id too.
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
      AND ei.event_id = ev.post_id
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
      AND ei.event_id = ev.post_id
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
      AND ei.event_id = ev.post_id
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
      AND ei.event_id = ev.post_id
      AND ev.post_id = event_post.id
      AND event_post.user_id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
