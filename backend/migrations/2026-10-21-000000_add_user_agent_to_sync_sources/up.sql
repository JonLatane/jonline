-- Which HTTP User-Agent a SyncSource sends when it fetches its feed, as a `SyncSourceUserAgent`
-- proto enum name (`NO_USER_AGENT` | `RELLM` | `CURL`). Some feeds sit behind bot protection that
-- only lets certain clients through (raleighnc.gov's Cloudflare rules admit `curl/*` and challenge
-- everything else, including a request with no User-Agent). Existing sources keep sending none,
-- exactly as before.
ALTER TABLE sync_sources ADD COLUMN user_agent TEXT NOT NULL DEFAULT 'NO_USER_AGENT';
