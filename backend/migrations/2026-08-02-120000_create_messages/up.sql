-- MESSAGES. Raw message bytes for inbound email (the full MIME blob delivered by the Stalwart
-- mail server -- see deploys/email) live in MinIO; this table indexes them once per message.
-- `messages` is also the home for future non-email messages (e.g. in-app direct messages via
-- from_user_id/recipient_type 'direct'), which is why the email-specific columns below are all
-- nullable. Recipients are broken out into message_recipients rather than a user_id column on
-- messages itself, so a message addressed to several local users doesn't duplicate the MinIO
-- blob/headers per recipient.
CREATE EXTENSION IF NOT EXISTS btree_gin;

CREATE TABLE messages (
  id BIGSERIAL PRIMARY KEY,
  -- Set for messages composed by a Jonline user (e.g. future in-app direct messages). NULL for
  -- inbound email, which has no local sender account. The /email endpoint never sets this.
  from_user_id BIGINT REFERENCES users ON DELETE SET NULL,
  subject VARCHAR,
  body_text TEXT,
  -- to/from/cc/bcc plus a short plaintext preview of the body, for inbound email only. See
  -- models::EmailHeaders. NULL for non-email messages.
  email_headers JSONB,
  -- The Message-ID header, used to deduplicate redelivery attempts from Stalwart (see
  -- web/email.rs) -- SMTP delivery is retried on transient failure, so without this a retried
  -- message would otherwise be stored twice. NULL for non-email messages.
  email_message_id VARCHAR,
  -- Path of the raw MIME blob in MinIO. NULL for non-email messages.
  email_minio_path VARCHAR,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  search_text tsvector NOT NULL DEFAULT ''::tsvector
);
-- Multiple NULLs are allowed by a unique index (NULLs are never considered equal), so this only
-- enforces dedup among messages that actually carry a Message-ID.
CREATE UNIQUE INDEX idx_messages_email_message_id ON messages(email_message_id);
CREATE INDEX idx_messages_search_text ON messages USING GIN (search_text);

-- Uses the 'simple' text search config throughout (no stemming, no per-language stopword list)
-- rather than 'english', for the same reason posts/users made the same switch: see
-- 2026-07-23-012047_add_search_text_no_stopwords -- 'english' silently drops common words like
-- "about" via its built-in stopword list, and this app's content isn't English-only anyway.
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

CREATE TYPE recipient_type AS ENUM ('to', 'cc', 'bcc', 'direct');

CREATE TABLE message_recipients (
  id BIGSERIAL PRIMARY KEY,
  message_id BIGINT NOT NULL REFERENCES messages ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  recipient_type recipient_type NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_message_recipients_user_id ON message_recipients(user_id, created_at);
CREATE UNIQUE INDEX idx_message_recipients_message_user ON message_recipients(message_id, user_id);
