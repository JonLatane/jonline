//! Link-preview summaries for Bluesky and Mastodon posts addressed through a Rellm server -- `/post/{id}@bluesky:`,
//! `/~{id}@bluesky:`, `/~{id}@mastodon:{host}` (see `Components.Posts.postHref` on the Elm side for how those ids are
//! built). Rellm doesn't store these posts, so there's nothing in the database to summarize.
//!
//! * **Bluesky** posts are looked up on Bluesky's public AppView (a fixed host, so a request path can't make the server
//!   contact anything else), with a short timeout, and the answer -- success or failure -- is cached for a while so a
//!   crawler hitting the same link, or a flood of requests for one, costs at most one lookup per interval.
//! * **Mastodon** posts get a generic summary and are *not* fetched: the instance host comes straight out of the
//!   request path, and having the server request an arbitrary host's URL on a visitor's say-so would be a
//!   request-forgery hole.

use std::{
    collections::HashMap,
    time::{Duration, Instant},
};

use lazy_static::lazy_static;
use rocket::{http::RawStr, tokio::sync::Mutex};
use serde_json::Value;

use super::RellmSummary;

#[derive(Debug, PartialEq, Eq, Clone)]
pub enum FederatedPost {
    Bluesky { did: String, rkey: String },
    Mastodon { host: String, status_id: String },
}

impl FederatedPost {
    /// `at://{did}/app.bsky.feed.post/{rkey}` for a Bluesky post.
    pub fn bluesky_uri(did: &str, rkey: &str) -> String {
        format!("at://{}/app.bsky.feed.post/{}", did, rkey)
    }
}

/// Recognizes `{id}@bluesky:` (or `{id}@bluesky`) / `{id}@mastodon:{host}` -- the id half of a federated post's route segment (no leading
/// `~`) -- percent-encoded or not. A Bluesky id is `{did}~{rkey}`; a Mastodon id is the
/// status id. Everything is validated, since it ends up in a lookup URL (Bluesky) or on a page (both).
pub fn parse_federated_id(raw: &str) -> Option<FederatedPost> {
    let decoded = RawStr::new(raw).percent_decode_lossy();
    let (id, host) = decoded.split_once('@')?;
    if let Some(instance) = host.strip_prefix("mastodon:") {
        let host = instance.to_ascii_lowercase();
        return if is_hostname(&host) && is_digits(id) {
            Some(FederatedPost::Mastodon {
                host,
                status_id: id.to_string(),
            })
        } else {
            None
        };
    }
    // A bare `@bluesky` means the same as `@bluesky:` (nothing is hosted at a host literally named `bluesky`).
    if host != "bluesky:" && host != "bluesky" {
        return None;
    }
    let (did, rkey) = id.split_once('~')?;
    if is_did(did) && is_record_key(rkey) {
        Some(FederatedPost::Bluesky {
            did: did.to_string(),
            rkey: rkey.to_string(),
        })
    } else {
        None
    }
}

fn is_digits(s: &str) -> bool {
    !s.is_empty() && s.len() <= 30 && s.chars().all(|c| c.is_ascii_digit())
}

fn is_hostname(s: &str) -> bool {
    s.len() <= 253
        && s.contains('.')
        && !s.starts_with('.')
        && !s.ends_with('.')
        && s.chars()
            .all(|c| c.is_ascii_alphanumeric() || c == '.' || c == '-')
}

fn is_did(s: &str) -> bool {
    s.starts_with("did:")
        && s.len() <= 128
        && s.chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, ':' | '.' | '-' | '_'))
}

fn is_record_key(s: &str) -> bool {
    !s.is_empty()
        && s.len() <= 512
        && s.chars()
            .all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_' | '~' | ':'))
}

/// What a Bluesky post's preview shows.
#[derive(Debug, PartialEq, Eq, Clone)]
pub struct BlueskyPreview {
    pub author: String,
    pub text: String,
    pub image: Option<String>,
}

/// Picks a Bluesky `app.bsky.feed.getPosts` response apart: the author (`displayName`, else `@handle`), the text, and
/// the first image -- an attached picture, a link card's thumbnail or a video's, else the author's avatar. `None` if
/// there's no post (deleted, or not public).
pub fn bluesky_preview_from_json(response: &Value) -> Option<BlueskyPreview> {
    let post = response.get("posts")?.get(0)?;
    let author = post.get("author")?;
    let handle = author.get("handle")?.as_str()?;
    let author_name = match author
        .get("displayName")
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|name| !name.is_empty())
    {
        Some(name) => name.to_string(),
        None => format!("@{}", handle),
    };
    let text = post
        .pointer("/record/text")
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string();

    let embed = post.get("embed");
    // `images#view`, `recordWithMedia#view` (its media is one of these), `external#view`, `video#view`.
    let candidates = [
        embed.and_then(|e| e.pointer("/images/0/fullsize")),
        embed.and_then(|e| e.pointer("/media/images/0/fullsize")),
        embed.and_then(|e| e.pointer("/external/thumb")),
        embed.and_then(|e| e.pointer("/media/external/thumb")),
        embed.and_then(|e| e.get("thumbnail")),
        embed.and_then(|e| e.pointer("/media/thumbnail")),
        author.get("avatar"),
    ];
    let image = candidates
        .into_iter()
        .flatten()
        .filter_map(Value::as_str)
        .find(|url| url.starts_with("https://"))
        .map(str::to_string);

    Some(BlueskyPreview {
        author: author_name,
        text,
        image,
    })
}

/// How a Bluesky post shows up as a link preview: "Author on Bluesky | Server", its text as the description.
pub fn bluesky_summary(
    preview: Option<BlueskyPreview>,
    server_name: &str,
    server_logo: Option<String>,
) -> RellmSummary {
    let fallback_image = server_logo.or(Some("/favicon.png".to_string()));
    match preview {
        Some(preview) => RellmSummary {
            title: Some(format!("{} on Bluesky | {}", preview.author, server_name)),
            description: Some(truncate(&preview.text, 300)).filter(|text| !text.is_empty()),
            image: preview.image.or(fallback_image),
        },
        None => RellmSummary {
            title: Some(format!("Bluesky Post | {}", server_name)),
            description: None,
            image: fallback_image,
        },
    }
}

/// Mastodon posts aren't looked up (see the module docs), so all the preview can say is where it's from.
pub fn mastodon_summary(
    host: &str,
    server_name: &str,
    server_logo: Option<String>,
) -> RellmSummary {
    RellmSummary {
        title: Some(format!("Mastodon Post from {} | {}", host, server_name)),
        description: None,
        image: server_logo.or(Some("/favicon.png".to_string())),
    }
}

/// `text` cut to at most `max` characters (on a character boundary), with an ellipsis if anything was cut.
pub fn truncate(text: &str, max: usize) -> String {
    let collapsed = text.split_whitespace().collect::<Vec<_>>().join(" ");
    if collapsed.chars().count() <= max {
        collapsed
    } else {
        let cut: String = collapsed.chars().take(max.saturating_sub(1)).collect();
        format!("{}…", cut.trim_end())
    }
}

// === Lookup + cache ===

const SUCCESS_TTL: Duration = Duration::from_secs(10 * 60);
const FAILURE_TTL: Duration = Duration::from_secs(60);
const MAX_ENTRIES: usize = 500;
const LOOKUP_TIMEOUT: Duration = Duration::from_secs(3);

/// A small time-limited cache: entries expire after the TTL they were stored with, and the whole thing is cleared if
/// it ever grows past `MAX_ENTRIES` (it only ever holds links someone actually requested, so this is a backstop).
pub struct TtlCache<V> {
    entries: HashMap<String, (Instant, V)>,
}

impl<V: Clone> TtlCache<V> {
    pub fn new() -> Self {
        TtlCache {
            entries: HashMap::new(),
        }
    }

    pub fn get(&self, key: &str, now: Instant) -> Option<V> {
        self.entries
            .get(key)
            .filter(|(expires_at, _)| *expires_at > now)
            .map(|(_, value)| value.clone())
    }

    pub fn put(&mut self, key: String, value: V, ttl: Duration, now: Instant) {
        if self.entries.len() >= MAX_ENTRIES {
            self.entries.retain(|_, (expires_at, _)| *expires_at > now);
            if self.entries.len() >= MAX_ENTRIES {
                self.entries.clear();
            }
        }
        self.entries.insert(key, (now + ttl, value));
    }
}

lazy_static! {
    static ref BLUESKY_CACHE: Mutex<TtlCache<Option<BlueskyPreview>>> = Mutex::new(TtlCache::new());
    static ref HTTP: reqwest::Client = reqwest::Client::builder()
        .timeout(LOOKUP_TIMEOUT)
        .user_agent("Rellm link preview")
        .build()
        .expect("a valid HTTP client");
}

async fn fetch_bluesky(did: &str, rkey: &str) -> Option<BlueskyPreview> {
    let response = HTTP
        .get("https://public.api.bsky.app/xrpc/app.bsky.feed.getPosts")
        .query(&[("uris", FederatedPost::bluesky_uri(did, rkey))])
        .send()
        .await
        .ok()?;
    if !response.status().is_success() {
        return None;
    }
    let json: Value = response.json().await.ok()?;
    bluesky_preview_from_json(&json)
}

async fn bluesky_preview(did: &str, rkey: &str) -> Option<BlueskyPreview> {
    let key = FederatedPost::bluesky_uri(did, rkey);
    if let Some(cached) = BLUESKY_CACHE.lock().await.get(&key, Instant::now()) {
        return cached;
    }
    let preview = fetch_bluesky(did, rkey).await;
    let ttl = if preview.is_some() {
        SUCCESS_TTL
    } else {
        FAILURE_TTL
    };
    BLUESKY_CACHE
        .lock()
        .await
        .put(key, preview.clone(), ttl, Instant::now());
    preview
}

/// The link-preview summary for a federated post.
pub async fn federated_summary(
    post: &FederatedPost,
    server_name: &str,
    server_logo: Option<String>,
) -> RellmSummary {
    match post {
        FederatedPost::Bluesky { did, rkey } => {
            bluesky_summary(bluesky_preview(did, rkey).await, server_name, server_logo)
        }
        FederatedPost::Mastodon { host, .. } => mastodon_summary(host, server_name, server_logo),
    }
}
