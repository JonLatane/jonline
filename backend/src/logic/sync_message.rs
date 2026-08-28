//! Builds the platform-agnostic `SyncMessage` pushed to every `SyncDestination` type
//! (`facebook_sync::post_post`/`post_event_instance`/`post_to_instagram`, `mastodon_sync::post_status`,
//! `bluesky_sync::post_record`). `rpcs::posts::sync_post`/`rpcs::events::sync_event_instance` each
//! build one of these *once*, from the raw Post/EventInstance fields, *before* dispatching on
//! `destination.configuration`'s variant -- so per-platform posting code only ever deals with
//! already-formatted content, not bespoke per-content-type structs (the old `EventInstancePost`/
//! `PostFacebookContent`, now folded into the two builders below).

use chrono::DateTime;
use chrono::Utc;

/// Platform-agnostic content to push to a `SyncDestination`.
#[derive(Debug, Clone)]
pub struct SyncMessage {
    /// Already-formatted body text -- see `build_event_instance_message`/`build_post_message` for
    /// how title/content/date-time-range/location get folded into this once, up front, instead of
    /// being reformatted per platform.
    pub text: String,
    /// Link back to this content (preferring this Jonline server's own frontend URL for it, falling
    /// back to the author's own external `link` -- see the builders below). Also already folded
    /// into `text` (as "Details & RSVP:"/"View post:"), since most platforms (Mastodon, Bluesky)
    /// have no separate link-preview mechanism and just expect it inline; kept here too since
    /// Facebook's Graph API *does* have a separate `link` param it uses for its preview card.
    pub link: Option<String>,
    /// Public download URLs of the content's attached media, in the same order as the underlying
    /// Post/EventInstance's `media` field. Empty for text-only content.
    pub media: Vec<String>,
}

/// Raw fields `build_event_instance_message` folds into a `SyncMessage.text` -- mirrors the old
/// `facebook_sync::EventInstancePost`.
pub struct EventInstanceMessageInput<'a> {
    pub title: &'a Option<String>,
    pub content: &'a Option<String>,
    /// Arbitrary external link the organizer set on the underlying `Post` (e.g. a ticketing site).
    /// Used only if `event_url` isn't set.
    pub link: &'a Option<String>,
    pub starts_at: DateTime<Utc>,
    pub ends_at: DateTime<Utc>,
    /// `EventInstance.location`'s `uniformly_formatted_address`, if any.
    pub location: &'a Option<String>,
    /// The IANA timezone `location` resolves to, if `logic::resolve_timezone` could geocode it.
    /// `starts_at`/`ends_at` are shown in this zone if set, otherwise in UTC.
    pub timezone: Option<chrono_tz::Tz>,
    /// Link to this event on this Jonline server's own frontend, if buildable (see
    /// `sync_event_instance`'s caller).
    pub event_url: &'a Option<String>,
    /// Public download URLs of the underlying Post's attached media.
    pub media: Vec<String>,
}

/// Builds an EventInstance's `SyncMessage` -- title, date/time range (in `timezone` if resolved,
/// else UTC), location, description, and a link back to the event, in that order. Mirrors what
/// `facebook_sync::format_message` used to build directly for Facebook; now shared by every
/// platform.
pub fn build_event_instance_message(input: EventInstanceMessageInput) -> SyncMessage {
    let mut lines = vec![];
    if let Some(title) = input.title.as_ref().filter(|t| !t.trim().is_empty()) {
        lines.push(title.clone());
    }
    let time_range = match input.timezone {
        Some(tz) => format_time_range(
            input.starts_at.with_timezone(&tz),
            input.ends_at.with_timezone(&tz),
        ),
        None => format_time_range(input.starts_at, input.ends_at),
    };
    lines.push(time_range);
    if let Some(location) = input.location.as_ref().filter(|l| !l.trim().is_empty()) {
        lines.push(format!("Location: {location}"));
    }
    if let Some(content) = input.content.as_ref().filter(|c| !c.trim().is_empty()) {
        lines.push(content.clone());
    }
    let link = input
        .event_url
        .as_ref()
        .filter(|l| !l.trim().is_empty())
        .or_else(|| input.link.as_ref().filter(|l| !l.trim().is_empty()))
        .cloned();
    if let Some(link) = &link {
        lines.push(format!("Details & RSVP: {link}"));
    }
    SyncMessage {
        text: lines.join("\n\n"),
        link,
        media: input.media,
    }
}

/// Raw fields `build_post_message` folds into a `SyncMessage.text` -- mirrors the old
/// `facebook_sync::PostFacebookContent`. Simpler than `EventInstanceMessageInput`: a `Post` has no
/// start/end time, timezone, or location.
pub struct PostMessageInput<'a> {
    pub title: &'a Option<String>,
    pub content: &'a Option<String>,
    /// Arbitrary external link the author set on the `Post` (e.g. an article/ticketing link). Used
    /// only if `post_url` isn't set.
    pub link: &'a Option<String>,
    /// Link to this `Post` on this Jonline server's own frontend, if buildable (see `sync_post`'s
    /// caller).
    pub post_url: &'a Option<String>,
    /// Public download URLs of the Post's attached media.
    pub media: Vec<String>,
}

/// Builds a Post's `SyncMessage` -- title, content, and a link back to it. Mirrors what
/// `facebook_sync::format_post_message` used to build directly for Facebook.
pub fn build_post_message(input: PostMessageInput) -> SyncMessage {
    let mut lines = vec![];
    if let Some(title) = input.title.as_ref().filter(|t| !t.trim().is_empty()) {
        lines.push(title.clone());
    }
    if let Some(content) = input.content.as_ref().filter(|c| !c.trim().is_empty()) {
        lines.push(content.clone());
    }
    let link = input
        .post_url
        .as_ref()
        .filter(|l| !l.trim().is_empty())
        .or_else(|| input.link.as_ref().filter(|l| !l.trim().is_empty()))
        .cloned();
    if let Some(link) = &link {
        lines.push(format!("View post: {link}"));
    }
    SyncMessage {
        text: lines.join("\n\n"),
        link,
        media: input.media,
    }
}

/// Generic over the timezone (`Utc` or a `chrono_tz::Tz` the caller already converted `starts_at`
/// and `ends_at` into) so this doesn't need to duplicate itself for each. Moved verbatim from
/// `facebook_sync::format_time_range`.
fn format_time_range<Tz: chrono::TimeZone>(starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> String
where
    Tz::Offset: std::fmt::Display,
{
    let start_date = starts_at.format("%A, %B %-d, %Y").to_string();
    let start_time = starts_at.format("%-I:%M %p").to_string();
    let zone = starts_at.format("%Z").to_string();
    if ends_at <= starts_at {
        return format!("{start_date} at {start_time} {zone}");
    }
    if starts_at.date_naive() == ends_at.date_naive() {
        let end_time = ends_at.format("%-I:%M %p").to_string();
        format!("{start_date} at {start_time} \u{2013} {end_time} {zone}")
    } else {
        let end = ends_at.format("%A, %B %-d, %Y at %-I:%M %p %Z").to_string();
        format!("{start_date} at {start_time} {zone} \u{2013} {end}")
    }
}

/// Truncates `text` to at most 300 characters (Bluesky's real limit is 300 *grapheme clusters*,
/// but plain char-count with a safety margin is a reasonable approximation without pulling in a
/// grapheme-segmentation crate) -- see `bluesky_sync::post_record`, the one platform that truncates
/// proactively rather than surfacing the API's own rejection.
pub fn truncate_for_bluesky(text: &str) -> String {
    let char_count = text.chars().count();
    if char_count <= 300 {
        return text.to_string();
    }
    let truncated: String = text.chars().take(296).collect();
    format!("{truncated}\u{2026}")
}
