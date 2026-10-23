//! Link-preview summaries for short Post/Event URLs (`/~id`) and for Bluesky/Mastodon posts addressed through a Rellm
//! server (`web::short_url_preview`, `web::federated_preview`). Nothing here touches the network: the Bluesky lookup
//! is exercised through its pure halves (id parsing, response-to-summary).

use std::time::{Duration, Instant};

use diesel::Connection;
use serde_json::json;

use crate::protos::*;
use crate::rpcs::get_server_configuration_proto;
use crate::tests::factories::*;
use crate::web::federated_preview::{
    BlueskyPreview, FederatedPost, TtlCache, bluesky_preview_from_json, bluesky_summary,
    mastodon_summary, parse_federated_id, truncate,
};
use crate::web::short_url_preview::{
    is_short_url_segment, rellm_short_url_summary, short_url_summary,
};

const DID: &str = "did:plc:wv5mhfadfpt6wmvoxedgqzyw";
const RKEY: &str = "3mte7ozu3qc2s";

fn bluesky() -> FederatedPost {
    FederatedPost::Bluesky {
        did: DID.to_string(),
        rkey: RKEY.to_string(),
    }
}

#[test]
fn parses_a_bluesky_id_with_either_host_spelling() {
    for host in ["bluesky:", "bluesky"] {
        assert_eq!(
            parse_federated_id(&format!("{}~{}@{}", DID, RKEY, host)),
            Some(bluesky())
        );
    }
}

#[test]
fn parses_a_mastodon_id() {
    assert_eq!(
        parse_federated_id("117462924798124768@mastodon:Mastodon.World"),
        Some(FederatedPost::Mastodon {
            host: "mastodon.world".to_string(),
            status_id: "117462924798124768".to_string()
        })
    );
}

#[test]
fn rejects_ids_that_are_not_well_formed_federated_posts() {
    for bad in [
        "",
        "4rAfoSKAuJo",                                                 // a Rellm id
        "4rAfoSKAuJo@jonline.io",                                      // another Rellm server
        &format!("{}~{}", DID, RKEY),                                  // no host
        &format!("nodid~{}@bluesky:", RKEY),                           // not a DID
        &format!("{}~@bluesky:", DID),                                 // no rkey
        &format!("{}~a<b>@bluesky:", DID),                             // markup in the rkey
        &format!("{}~a/b@bluesky:", DID),                              // path in the rkey
        &format!("at://{}/app.bsky.feed.post/{}@bluesky:", DID, RKEY), // the long `at://` form is gone
        "abc@mastodon:mastodon.social",                                // status ids are numeric
        "123@mastodon:localhost",                                      // not a public domain name
        "123@mastodon:evil.example/x",                                 // path smuggled in the host
        "123@mastodon:evil.example:8080",                              // port
        "123@mastodon:evil.example@other",                             // second @
    ] {
        assert_eq!(parse_federated_id(bad), None, "{}", bad);
    }
}

fn response(embed: serde_json::Value) -> serde_json::Value {
    json!({ "posts": [{
        "author": { "handle": "sarah.bsky.social", "displayName": "Sarah K", "avatar": "https://cdn.bsky.app/avatar.jpg" },
        "record": { "text": "Hello from Bluesky" },
        "embed": embed
    }]})
}

fn preview_of(embed: serde_json::Value) -> BlueskyPreview {
    bluesky_preview_from_json(&response(embed)).expect("a preview")
}

#[test]
fn a_bluesky_preview_prefers_the_posts_own_picture() {
    let images = preview_of(
        json!({ "images": [{ "fullsize": "https://cdn.bsky.app/full.jpg", "thumb": "https://cdn.bsky.app/t.jpg" }] }),
    );
    assert_eq!(
        images.image.as_deref(),
        Some("https://cdn.bsky.app/full.jpg")
    );
    assert_eq!(
        (images.author.as_str(), images.text.as_str()),
        ("Sarah K", "Hello from Bluesky")
    );

    let with_media = preview_of(
        json!({ "media": { "images": [{ "fullsize": "https://cdn.bsky.app/m.jpg" }] }, "record": {} }),
    );
    assert_eq!(
        with_media.image.as_deref(),
        Some("https://cdn.bsky.app/m.jpg")
    );

    let link_card = preview_of(
        json!({ "external": { "thumb": "https://cdn.bsky.app/card.jpg", "title": "x" } }),
    );
    assert_eq!(
        link_card.image.as_deref(),
        Some("https://cdn.bsky.app/card.jpg")
    );

    let video = preview_of(json!({ "thumbnail": "https://video.bsky.app/thumb.jpg" }));
    assert_eq!(
        video.image.as_deref(),
        Some("https://video.bsky.app/thumb.jpg")
    );
}

#[test]
fn a_bluesky_preview_falls_back_to_the_avatar_and_ignores_non_https_images() {
    assert_eq!(
        preview_of(json!(null)).image.as_deref(),
        Some("https://cdn.bsky.app/avatar.jpg")
    );
    let insecure = preview_of(json!({ "images": [{ "fullsize": "javascript:alert(1)" }] }));
    assert_eq!(
        insecure.image.as_deref(),
        Some("https://cdn.bsky.app/avatar.jpg")
    );
}

#[test]
fn a_bluesky_author_without_a_display_name_is_shown_by_handle() {
    let preview = bluesky_preview_from_json(&json!({ "posts": [{
        "author": { "handle": "sarah.bsky.social", "displayName": "  " },
        "record": { "text": "hi" }
    }]}))
    .unwrap();
    assert_eq!(preview.author, "@sarah.bsky.social");
    assert_eq!(preview.image, None);
}

#[test]
fn no_post_means_no_preview() {
    assert_eq!(bluesky_preview_from_json(&json!({ "posts": [] })), None);
    assert_eq!(
        bluesky_preview_from_json(&json!({ "error": "NotFound" })),
        None
    );
}

#[test]
fn summaries_for_federated_posts() {
    let summary = bluesky_summary(
        Some(preview_of(json!(null))),
        "Rellm HQ",
        Some("/media/logo".into()),
    );
    assert_eq!(
        summary.title.as_deref(),
        Some("Sarah K on Bluesky | Rellm HQ")
    );
    assert_eq!(summary.description.as_deref(), Some("Hello from Bluesky"));
    assert_eq!(
        summary.image.as_deref(),
        Some("https://cdn.bsky.app/avatar.jpg")
    );

    let missing = bluesky_summary(None, "Rellm HQ", Some("/media/logo".into()));
    assert_eq!(missing.title.as_deref(), Some("Bluesky Post | Rellm HQ"));
    assert_eq!(
        (missing.description, missing.image.as_deref()),
        (None, Some("/media/logo"))
    );

    let mastodon = mastodon_summary("mastodon.world", "Rellm HQ", None);
    assert_eq!(
        mastodon.title.as_deref(),
        Some("Mastodon Post from mastodon.world | Rellm HQ")
    );
    assert_eq!(mastodon.image.as_deref(), Some("/favicon.png"));
}

#[test]
fn long_text_is_cut_on_a_character_boundary_with_an_ellipsis() {
    assert_eq!(truncate("short   text\nhere", 50), "short text here");
    let long = "é".repeat(400);
    let cut = truncate(&long, 300);
    assert_eq!(cut.chars().count(), 300);
    assert!(cut.ends_with('…'));
}

#[test]
fn the_cache_expires_entries_and_is_bounded() {
    let now = Instant::now();
    let mut cache: TtlCache<u32> = TtlCache::new();
    cache.put("a".into(), 1, Duration::from_secs(60), now);
    assert_eq!(cache.get("a", now + Duration::from_secs(59)), Some(1));
    assert_eq!(cache.get("a", now + Duration::from_secs(61)), None);
    assert_eq!(cache.get("missing", now), None);
    for i in 0..2000 {
        cache.put(format!("k{}", i), i, Duration::from_secs(60), now);
    }
    // It never grows without bound, and the newest entry is always there.
    assert_eq!(cache.get("k1999", now), Some(1999));
}

#[test]
fn recognizes_short_url_segments() {
    for segment in ["~abc", ":abc", "-abc", "@abc", "=x", "!x"] {
        assert!(is_short_url_segment(segment), "{}", segment);
    }
    for segment in ["someuser", "weddings", "", "4rAfoSKAuJo"] {
        assert!(!is_short_url_segment(segment), "{}", segment);
    }
}

fn public_post_opts(title: &str, content: &str) -> PostOpts {
    PostOpts {
        visibility: Visibility::GlobalPublic,
        title: Some(title.to_string()),
        content: Some(content.to_string()),
        ..Default::default()
    }
}

/// Short-URL previews of what's in the database, one transaction per spec like the rest of the suite.
fn with_conn(spec: impl FnOnce(&mut crate::db_connection::PgPooledConnection)) {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        spec(conn);
        Ok(())
    });
}

fn summary_title_and_description(
    conn: &mut crate::db_connection::PgPooledConnection,
    post_id: i64,
) -> (String, Option<String>) {
    let configuration = get_server_configuration_proto(conn).unwrap();
    let id = crate::marshaling::ToProtoId::to_proto_id(&post_id);
    let summary = rellm_short_url_summary(&id, &configuration, conn).expect("a summary");
    (summary.title.expect("a title"), summary.description)
}

#[test]
fn a_short_url_for_a_public_post_previews_that_post() {
    with_conn(|conn| {
        let author = create_user(conn, "short_url_author");
        let post = create_post(
            conn,
            Some(&author),
            public_post_opts("Hello World", "The body"),
        );
        let (title, description) = summary_title_and_description(conn, post.id);
        assert!(
            title.starts_with("Hello World | Post Details | "),
            "{}",
            title
        );
        assert_eq!(description.as_deref(), Some("The body"));
    });
}

#[test]
fn a_short_url_for_a_post_the_public_cannot_see_gives_the_generic_summary() {
    with_conn(|conn| {
        let author = create_user(conn, "short_url_private_author");
        let post = create_post(
            conn,
            Some(&author),
            PostOpts {
                visibility: Visibility::Limited,
                title: Some("Secret plans".to_string()),
                content: Some("Nobody should see this".to_string()),
                ..Default::default()
            },
        );
        let (title, description) = summary_title_and_description(conn, post.id);
        assert!(title.starts_with("Post Details | "), "{}", title);
        assert!(!title.contains("Secret"));
        assert_eq!(description, None);
    });
}

#[test]
fn short_urls_for_an_event_or_one_of_its_occasions_preview_the_event() {
    with_conn(|conn| {
        let author = create_user(conn, "short_url_event_author");
        let (event, event_post) = create_event(
            conn,
            &author,
            EventOpts {
                visibility: Visibility::GlobalPublic,
                title: Some("Block Party".to_string()),
                ..Default::default()
            },
        );
        let (_occasion, occasion_post) = create_occasion(
            conn,
            &event,
            Some(&author),
            OccasionOpts {
                visibility: Visibility::GlobalPublic,
                ..Default::default()
            },
        );
        for post_id in [event_post.id, occasion_post.id] {
            let (title, _) = summary_title_and_description(conn, post_id);
            assert!(
                title.starts_with("Block Party | Event Details | "),
                "{}",
                title
            );
        }
    });
}

#[test]
fn short_urls_that_name_nothing_still_give_a_generic_summary() {
    with_conn(|conn| {
        let configuration = get_server_configuration_proto(conn).unwrap();
        for id in ["zzzzzzzz", "someone@other.example"] {
            let summary = rellm_short_url_summary(id, &configuration, conn).expect("a summary");
            assert!(
                summary.title.unwrap().starts_with("Post Details | "),
                "{}",
                id
            );
        }
    });
}

#[tokio::test]
async fn short_url_summary_sends_federated_ids_to_the_federated_previews_and_ignores_an_empty_one()
{
    // No database access on these paths (and `get_server_configuration_proto` would *create* a configuration row
    // outside a transaction, leaking state into other specs), so an in-memory configuration is all this needs.
    let mut conn = test_conn();
    let configuration = ServerConfiguration::default();
    // Mastodon is never looked up, so this needs no network either.
    let summary = short_url_summary(
        "~117462924798124768@mastodon:mastodon.world",
        &configuration,
        &mut conn,
    )
    .await
    .expect("a summary");
    assert!(
        summary
            .title
            .unwrap()
            .starts_with("Mastodon Post from mastodon.world | Rellm")
    );
    assert_eq!(summary.description, None);

    assert!(
        short_url_summary("~", &configuration, &mut conn)
            .await
            .is_none()
    );
}
