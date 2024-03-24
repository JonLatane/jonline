-- Add unauthenticated_star_count column to posts table
ALTER TABLE posts ADD COLUMN unauthenticated_star_count BIGINT NOT NULL DEFAULT 0;
