-- messages.search_text's 'D' weight (2026-08-02-120000_create_messages,
-- 2026-08-17-120000_add_group_members_to_messages_search_text) indexed `p_email_headers::text`
-- wholesale -- which does surface the actual From/To/Cc/Bcc addresses, but also tokenizes the
-- JSONB's own key names ("from", "to", "cc", "bcc") and punctuation as literal searchable terms,
-- so e.g. a plain search for "to" would spuriously match every email message. Extracting each
-- field's string value(s) directly instead indexes only the addresses themselves.
-- `p_email_headers` (and each of its `to`/`cc`/`bcc` arrays) can be NULL/absent -- see that
-- column's own comment in 2026-08-02-120000_create_messages -- hence the `coalesce`s, both here
-- and around this function's own call site below.
CREATE FUNCTION messages_addresses_search_text(p_email_headers JSONB) RETURNS TEXT AS $$
  SELECT string_agg(v, ' ') FROM (
    SELECT p_email_headers ->> 'from' AS v
    UNION ALL
    SELECT jsonb_array_elements_text(coalesce(p_email_headers -> 'to', '[]'::jsonb))
    UNION ALL
    SELECT jsonb_array_elements_text(coalesce(p_email_headers -> 'cc', '[]'::jsonb))
    UNION ALL
    SELECT jsonb_array_elements_text(coalesce(p_email_headers -> 'bcc', '[]'::jsonb))
  ) addresses
  WHERE v IS NOT NULL;
$$ LANGUAGE sql IMMUTABLE;

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
    setweight(to_tsvector('simple', coalesce(messages_addresses_search_text(p_email_headers), '')), 'D');
$$ LANGUAGE sql IMMUTABLE;

-- Backfill existing rows -- the trigger only fires on future INSERT/UPDATE.
UPDATE messages
SET search_text = messages_build_search_text(
  messages.subject,
  messages.body_text,
  messages.email_headers,
  messaging_group_member_search_text(messages.messaging_group_id)
);
