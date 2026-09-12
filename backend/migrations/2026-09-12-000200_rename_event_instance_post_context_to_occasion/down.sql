-- This file should undo anything in `up.sql`
UPDATE posts SET context = 'EVENT_INSTANCE' WHERE context = 'OCCASION';
