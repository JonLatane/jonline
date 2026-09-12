-- posts.context stores the PostContext enum as its string name (see
-- ToStringPostContext/ToProtoPostContext in post_marshaling.rs). Renaming the
-- EVENT_INSTANCE enum value to OCCASION (see posts.proto) means existing rows written with the
-- old name would no longer round-trip through `to_proto_post_context` -- update them to match.
UPDATE posts SET context = 'OCCASION' WHERE context = 'EVENT_INSTANCE';
