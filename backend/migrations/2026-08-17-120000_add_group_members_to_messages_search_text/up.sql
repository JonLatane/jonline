-- Extends messages.search_text (2026-08-02-120000_create_messages) to also match the username and
-- real_name of every user in the message's MessagingGroup -- not just its sender, which is all
-- `GetMessages`' separate `users::search_text` join (see rpcs::messages::get_messages) currently
-- covers. Same cross-table denormalization trigger pattern posts.search_text uses for its single
-- author (see 2026-07-22-144348_add_search_text_to_posts), except a MessagingGroup can have several
-- members, so `messaging_group_member_search_text` folds all of `sorted_user_ids` in via
-- `string_agg` rather than looking up one `user_id`.
CREATE FUNCTION messaging_group_member_search_text(p_messaging_group_id BIGINT) RETURNS TEXT AS $$
  SELECT string_agg(coalesce(u.username, '') || ' ' || coalesce(u.real_name, ''), ' ')
  FROM messaging_groups mg
  JOIN users u ON u.id = ANY(mg.sorted_user_ids)
  WHERE mg.id = p_messaging_group_id;
$$ LANGUAGE sql STABLE;

DROP TRIGGER messages_search_text_update ON messages;
DROP FUNCTION messages_search_text_trigger();
DROP FUNCTION messages_build_search_text(VARCHAR, TEXT, JSONB);

CREATE FUNCTION messages_build_search_text(
  p_subject VARCHAR,
  p_body_text TEXT,
  p_email_headers JSONB,
  p_member_text TEXT
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_member_text, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_subject, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_body_text, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_email_headers::text, '')), 'D');
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION messages_search_text_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_text := messages_build_search_text(
    NEW.subject,
    NEW.body_text,
    NEW.email_headers,
    messaging_group_member_search_text(NEW.messaging_group_id)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- `messaging_group_id` is now in the trigger's column list too: a message never actually changes
-- group after creation today, but if that ever changes, search_text should follow it.
CREATE TRIGGER messages_search_text_update
  BEFORE INSERT OR UPDATE OF subject, body_text, email_headers, messaging_group_id ON messages
  FOR EACH ROW EXECUTE FUNCTION messages_search_text_trigger();

-- Keeps messages.search_text in sync when a group member's username/real_name changes -- mirrors
-- users_search_text_trigger's role for posts.search_text (same migration cited above). Groups
-- themselves are immutable once created (see find_or_create_messaging_group), so no analogous
-- trigger is needed on messaging_groups.
CREATE FUNCTION users_messages_search_text_trigger() RETURNS trigger AS $$
BEGIN
  IF NEW.username IS DISTINCT FROM OLD.username OR NEW.real_name IS DISTINCT FROM OLD.real_name THEN
    UPDATE messages
    SET search_text = messages_build_search_text(
      messages.subject,
      messages.body_text,
      messages.email_headers,
      messaging_group_member_search_text(messages.messaging_group_id)
    )
    WHERE messages.messaging_group_id IN (
      SELECT id FROM messaging_groups WHERE sorted_user_ids @> ARRAY[NEW.id]
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_messages_search_text_update
  AFTER UPDATE OF username, real_name ON users
  FOR EACH ROW EXECUTE FUNCTION users_messages_search_text_trigger();

-- Backfill existing rows.
UPDATE messages
SET search_text = messages_build_search_text(
  messages.subject,
  messages.body_text,
  messages.email_headers,
  messaging_group_member_search_text(messages.messaging_group_id)
);
