-- Backs `GetMessagesRequest.from_email` (see get_messages.rs's `get_by_from_email`) -- the
-- client-side "grouped by sender" fallback a message falls into when it has no visible
-- `messaging_group` (see that field's own proto doc comment). Partial and expression-based
-- rather than a plain column index: `email_headers` is only ever set for inbound email (see its
-- own column comment in 2026-08-02-120000_create_messages), and it's the `from` key inside that
-- JSONB blob -- not the row itself -- that `get_by_from_email` filters on.
CREATE INDEX idx_messages_email_headers_from ON messages ((email_headers ->> 'from'))
  WHERE email_headers IS NOT NULL;
