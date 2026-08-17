DROP TRIGGER IF EXISTS users_messages_search_text_update ON users;
DROP FUNCTION IF EXISTS users_messages_search_text_trigger();

DROP TRIGGER IF EXISTS messages_search_text_update ON messages;
DROP FUNCTION IF EXISTS messages_search_text_trigger();
DROP FUNCTION IF EXISTS messages_build_search_text(VARCHAR, TEXT, JSONB, TEXT);
DROP FUNCTION IF EXISTS messaging_group_member_search_text(BIGINT);

CREATE FUNCTION messages_build_search_text(
  p_subject VARCHAR,
  p_body_text TEXT,
  p_email_headers JSONB
) RETURNS tsvector AS $$
  SELECT
    setweight(to_tsvector('simple', coalesce(p_subject, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(p_body_text, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(p_email_headers::text, '')), 'D');
$$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION messages_search_text_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_text := messages_build_search_text(NEW.subject, NEW.body_text, NEW.email_headers);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER messages_search_text_update
  BEFORE INSERT OR UPDATE OF subject, body_text, email_headers ON messages
  FOR EACH ROW EXECUTE FUNCTION messages_search_text_trigger();

UPDATE messages
SET search_text = messages_build_search_text(subject, body_text, email_headers);
