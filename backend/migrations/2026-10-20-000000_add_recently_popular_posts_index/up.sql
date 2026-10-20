-- Backs `GetPosts`' RECENTLY_POPULAR_POSTS listing (`rpcs::posts::get_posts::get_recently_popular_posts`).
--
-- That listing scores every visible top-level post published in the last 14 days by
-- (unauthenticated_star_count + 2 * response_count + 1) / (age_hours + 2) ^ 1.5, then takes the top
-- page. The score depends on the current time, so it can't be indexed itself; what *can* be is the
-- candidate set. This is a partial index over exactly the rows that listing considers (top-level
-- posts by a real author), ordered by `sort_published_at` so the 14-day window is a single range scan,
-- and it INCLUDEs the two engagement columns so the scoring happens straight off the index without a
-- heap fetch for each candidate (visibility/moderation/author joins still hit the heap, but only for
-- the rows the planner keeps).
CREATE INDEX idx_posts_recently_popular
    ON posts (context, sort_published_at DESC)
    INCLUDE (unauthenticated_star_count, response_count)
    WHERE parent_post_id IS NULL AND user_id IS NOT NULL;
