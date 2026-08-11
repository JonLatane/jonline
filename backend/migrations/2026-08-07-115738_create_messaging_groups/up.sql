-- MESSAGING_GROUPS. Every message now belongs to exactly one messaging_group -- the canonical
-- conversation between its participants. sorted_user_ids is normalized to ascending,
-- deduplicated order (by application code) so that finding-or-creating the group for a given
-- set of participants is a single equality lookup rather than a set-membership query; the unique
-- index below both accelerates that lookup and enforces one canonical group per distinct
-- participant set. Bcc'd recipients are deliberately excluded here -- they're invisible to the
-- other participants by design, so including them would leak their presence to anyone who saw
-- the group's membership. Bcc delivery continues to go through message_recipients (see
-- 2026-08-02-120000_create_messages), which is why a message with no local To/Cc recipients (a
-- purely Bcc'd or fully-external-recipient email) naturally lands in the '{}' group -- there's
-- nothing group-worthy about it.
--
-- sorted_user_ids has no FK to users -- Postgres can't constrain individual array elements -- so
-- deleting a user leaves their id stranded in any group they were part of. Accepted as a known
-- gap for now rather than solved with a scrub-on-delete trigger.
CREATE TABLE messaging_groups (
  id BIGSERIAL PRIMARY KEY,
  sorted_user_ids BIGINT[] NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
-- Exact-match lookup at group creation time: "does a group for this participant set already
-- exist?" Btree supports whole-array equality/ordering natively, and the UNIQUE constraint is
-- what makes a participant set map to exactly one canonical group.
CREATE UNIQUE INDEX idx_messaging_groups_sorted_user_ids ON messaging_groups(sorted_user_ids);
-- Membership lookup at read time: "which groups is user X in?" (e.g. a user's inbox). That's a
-- containment query (sorted_user_ids @> ARRAY[x]), which the btree index above can't serve --
-- GIN is needed to look up individual elements within the array.
CREATE INDEX idx_messaging_groups_sorted_user_ids_gin ON messaging_groups USING GIN (sorted_user_ids);

-- No production data to migrate -- start messages.messaging_group_id NOT NULL from an empty
-- table rather than backfilling. Cascades to message_recipients via its existing FK.
DELETE FROM messages;

ALTER TABLE messages
  ADD COLUMN messaging_group_id BIGINT NOT NULL REFERENCES messaging_groups;
-- Postgres doesn't index FK columns automatically; this is the "all messages in this group,
-- newest first" query the UI will run constantly.
CREATE INDEX idx_messages_messaging_group_id ON messages(messaging_group_id, created_at);
