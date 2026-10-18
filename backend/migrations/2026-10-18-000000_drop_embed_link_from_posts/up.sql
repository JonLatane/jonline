-- Linking to a supported social media post (or a Rellm/Bluesky/Mastodon post) now always embeds it, so the
-- per-post `embed_link` opt-in flag goes away.
ALTER TABLE posts DROP COLUMN embed_link;
