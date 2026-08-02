-- EMAIL MODELS. Raw message bytes (the full MIME blob delivered by the Stalwart mail server --
-- see deploys/email) live in MinIO; this table indexes them once per message. Recipients are
-- broken out into email_message_recipients rather than a user_id column on email_messages itself,
-- so a message addressed to several local users doesn't duplicate the MinIO blob/headers per
-- recipient.
CREATE TABLE email_messages (
  id BIGSERIAL PRIMARY KEY,
  -- The Message-ID header, used to deduplicate redelivery attempts from Stalwart (see
  -- web/email.rs) -- SMTP delivery is retried on transient failure, so without this a retried
  -- message would otherwise be stored twice.
  message_id VARCHAR NOT NULL,
  minio_path VARCHAR NOT NULL,
  -- to/from/cc/bcc/subject plus a short plaintext preview of the body. See
  -- models::EmailHeaders.
  headers JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_email_messages_message_id ON email_messages(message_id);

CREATE TABLE email_message_recipients (
  id BIGSERIAL PRIMARY KEY,
  email_message_id BIGINT NOT NULL REFERENCES email_messages ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  -- "to", "cc", or "bcc".
  recipient_type VARCHAR NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_email_message_recipients_user_id ON email_message_recipients(user_id, created_at);
CREATE UNIQUE INDEX idx_email_message_recipients_message_user ON email_message_recipients(email_message_id, user_id);
