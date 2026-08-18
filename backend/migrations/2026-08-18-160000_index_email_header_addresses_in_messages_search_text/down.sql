CREATE OR REPLACE FUNCTION messages_build_search_text(
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

DROP FUNCTION messages_addresses_search_text(JSONB);

UPDATE messages
SET search_text = messages_build_search_text(
  messages.subject,
  messages.body_text,
  messages.email_headers,
  messaging_group_member_search_text(messages.messaging_group_id)
);
