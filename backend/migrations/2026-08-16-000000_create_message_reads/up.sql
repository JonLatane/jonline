-- MESSAGE_READS. One row per (message, user) once that user has read that Message -- absence of
-- a row means unread. Backs `Message.current_user_read`/`MarkMessageReadRequest` (see
-- protos/messages.proto), which the Elm/Tamagui clients use to badge unread counts per
-- MessagingGroup. Composite primary key, no separate id column -- a user can only ever have one
-- read record per Message, so there's nothing an extra surrogate key would let us express;
-- mirrors event_instance_sync_destinations (see
-- 2026-08-09-205953_create_event_sync_destinations) for the precedent.
CREATE TABLE message_reads (
  message_id BIGINT NOT NULL REFERENCES messages ON DELETE CASCADE,
  user_id BIGINT NOT NULL REFERENCES users ON DELETE CASCADE,
  read_at TIMESTAMP NOT NULL DEFAULT NOW(),
  PRIMARY KEY (message_id, user_id)
);
-- Powers "how many unread messages does this user have, per MessagingGroup" (an anti-join against
-- this table, filtered by user_id) -- the query `mark_message_read`'s own doc and the Elm unread
-- badges both rely on.
CREATE INDEX idx_message_reads_user_id ON message_reads(user_id);
