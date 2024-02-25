-- For each event_instance, add a post.
-- At the end, events_instances.post_id should be non-empty for every event_instance.

INSERT INTO posts (user_id, context)
  SELECT event_posts.user_id, 'EVENT_INSTANCE'
  FROM posts AS event_posts
    INNER JOIN events ON events.post_id = event_posts.id
    INNER JOIN event_instances ON event_instances.event_id = events.id
  WHERE NOT EXISTS (
    SELECT 1
    FROM posts
    WHERE posts.id = event_instances.post_id
    AND posts.context = 'EVENT_INSTANCE'
  )
;

DO $$
  DECLARE instance_posts RECORD;
  BEGIN
    FOR instance_posts IN (
      SELECT id FROM posts WHERE context='EVENT_INSTANCE' AND
          NOT EXISTS (
            SELECT 1
            FROM event_instances
            WHERE event_instances.post_id = posts.id
          )
    )
    LOOP
      UPDATE event_instances
      SET post_id = instance_posts.id
      WHERE id IN (
        SELECT id FROM event_instances
        WHERE post_id IS NULL
        LIMIT 1
      );
    END LOOP;
  END;
$$ LANGUAGE plpgsql;

ALTER TABLE event_instances ALTER COLUMN post_id SET NOT NULL;
