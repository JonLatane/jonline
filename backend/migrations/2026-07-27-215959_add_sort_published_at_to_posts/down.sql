DROP INDEX idx_post_vis_sort_published;
DROP INDEX idx_post_vis_user_sort_published;
DROP INDEX idx_post_vis_parent_sort_published;

CREATE INDEX idx_post_vis_parent_created ON posts(context, visibility, parent_post_id, created_at);
CREATE INDEX idx_post_vis_user_created ON posts(context, visibility, user_id, created_at);

ALTER TABLE posts DROP COLUMN sort_published_at;
