//! Specs for `logic::sync_message`'s `SyncMessage` builders and Bluesky truncation helper --
//! pure functions, no network/DB involved.

use chrono::TimeZone;

use crate::logic::{
    build_event_instance_message, build_post_message, truncate_for_bluesky,
    EventInstanceMessageInput, MediaAttachment, PostMessageInput,
};

#[test]
fn truncate_for_bluesky_leaves_short_text_untouched() {
    assert_eq!(truncate_for_bluesky("short"), "short");
}

#[test]
fn truncate_for_bluesky_truncates_long_text_with_an_ellipsis() {
    let text = "a".repeat(500);
    let truncated = truncate_for_bluesky(&text);
    assert_eq!(truncated.chars().count(), 297); // 296 chars + ellipsis
    assert!(truncated.ends_with('\u{2026}'));
}

#[test]
fn truncate_for_bluesky_leaves_exactly_300_chars_untouched() {
    let text = "a".repeat(300);
    assert_eq!(truncate_for_bluesky(&text), text);
}

#[test]
fn build_post_message_includes_title_content_and_link() {
    let title = Some("Test Post".to_string());
    let content = Some("Check this out!".to_string());
    let link = None;
    let post_url = Some("https://example.com/post/abc".to_string());

    let message = build_post_message(PostMessageInput {
        title: &title,
        content: &content,
        link: &link,
        post_url: &post_url,
        media: vec![MediaAttachment {
            url: "https://example.com/media/1".to_string(),
            content_type: "image/jpeg".to_string(),
        }],
    });

    assert_eq!(
        message.text,
        "Test Post\n\nCheck this out!\n\nView post: https://example.com/post/abc"
    );
    assert_eq!(message.link, Some("https://example.com/post/abc".to_string()));
    assert_eq!(
        message.media,
        vec![MediaAttachment {
            url: "https://example.com/media/1".to_string(),
            content_type: "image/jpeg".to_string(),
        }]
    );
}

#[test]
fn build_event_instance_message_includes_time_range_and_location() {
    let title = Some("Test Event".to_string());
    let content = Some("Come join us!".to_string());
    let link = None;
    let location = Some("123 Main St".to_string());
    let event_url = Some("https://example.com/event/abc".to_string());
    let starts_at = chrono::Utc.with_ymd_and_hms(2099, 1, 1, 9, 0, 0).unwrap();
    let ends_at = chrono::Utc.with_ymd_and_hms(2099, 1, 1, 11, 0, 0).unwrap();

    let message = build_event_instance_message(EventInstanceMessageInput {
        title: &title,
        content: &content,
        link: &link,
        starts_at,
        ends_at,
        location: &location,
        timezone: None,
        event_url: &event_url,
        media: vec![],
    });

    assert!(message.text.starts_with("Test Event\n\n"));
    assert!(message.text.contains("Location: 123 Main St"));
    assert!(message.text.contains("Come join us!"));
    assert!(message
        .text
        .ends_with("Details & RSVP: https://example.com/event/abc"));
    assert_eq!(
        message.link,
        Some("https://example.com/event/abc".to_string())
    );
}
