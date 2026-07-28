-- Posts are meant to be listed by "effective publication time": `published_at` when a post has
-- been made SERVER_PUBLIC/GLOBAL_PUBLIC at some point (set once, immutable - see CreatePost /
-- UpdatePost), falling back to `created_at` for posts that have never been published (still
-- PRIVATE/LIMITED, or federation-context/reply rows that don't carry publication semantics).
--
-- `sort_published_at` is a STORED generated column computing COALESCE(published_at, created_at)
-- so every GetPosts branch can order by one plain, indexable timestamp column instead of each
-- query having to repeat a COALESCE expression (which a plain btree index can't be built against
-- as cleanly as a real column).
ALTER TABLE posts ADD COLUMN sort_published_at TIMESTAMP
  GENERATED ALWAYS AS (COALESCE(published_at, created_at)) STORED NOT NULL;

-- Superseded by the sort_published_at-based indexes below - GetPosts no longer orders by
-- created_at alone.
DROP INDEX idx_post_vis_parent_created;
DROP INDEX idx_post_vis_user_created;

-- Mirrors the dropped indexes' shapes, swapping created_at for sort_published_at:
--   - parent_post_id variant serves the default Post-context feed (get_public_and_following_posts)
--     and reply listings (get_replies_to_post_ids), both filtered on parent_post_id.
--   - user_id variant serves author-scoped listings (get_user_posts).
--   - the plain (context, visibility, sort_published_at) index serves listings that filter
--     through a join table rather than a posts column directly (get_my_group_posts,
--     get_following_posts, get_group_posts), where posts-table columns alone can't cover the
--     join filter but the sort key still benefits from being indexed.
CREATE INDEX idx_post_vis_parent_sort_published ON posts(context, visibility, parent_post_id, sort_published_at);
CREATE INDEX idx_post_vis_user_sort_published ON posts(context, visibility, user_id, sort_published_at);
CREATE INDEX idx_post_vis_sort_published ON posts(context, visibility, sort_published_at);
