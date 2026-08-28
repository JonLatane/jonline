//! Specs for `logic::facebook_sync`'s Graph API interaction correctness (token exchange, Page
//! lookup, posting, Instagram's linked-account lookup + 2-step publish flow) run against
//! `factories::serve_facebook_graph_api`/`factories::serve_facebook_graph_api_instagram` instead of
//! the real Facebook/Instagram Graph API. RPC-level permission/ownership handling is covered
//! separately by `sync_destination_rpc_tests`/`post_sync_rpc_tests`. `SyncMessage`'s own
//! text-formatting correctness is covered by `sync_message_tests`.

use chrono::{TimeZone, Utc};
use tonic::Code;

use crate::logic::{
    connect_facebook_page_at, get_linked_instagram_business_account_at, post_event_instance_at,
    post_post_at, post_to_instagram_at, SyncMessage,
};
use crate::models;
use crate::tests::factories::*;

/// `app_id`/`app_secret` are this Jonline server's own Facebook App credentials (now sourced from
/// `ServerConfiguration.federation_info.facebook_auth_config`, not an env var) -- their actual
/// value doesn't matter against a mock server, only that they're passed through.
const TEST_APP_ID: &str = "test-app-id";
const TEST_APP_SECRET: &str = "test-app-secret";

fn message(text: &str, link: Option<&str>) -> SyncMessage {
    SyncMessage {
        text: text.to_string(),
        link: link.map(str::to_string),
        media: vec![],
    }
}

#[test]
fn connect_succeeds_for_a_page_the_user_manages() {
    let base_url = serve_facebook_graph_api(Some(("123", "Test Page", "page-token")), "unused");

    let connection = connect_facebook_page_at(
        &base_url,
        TEST_APP_ID,
        TEST_APP_SECRET,
        "short-lived-token",
        "123",
    )
    .expect("connect should succeed");
    assert_eq!(connection.page_id, "123");
    assert_eq!(connection.page_name, "Test Page");
    assert_eq!(connection.access_token, "page-token");
}

#[test]
fn connect_fails_for_a_page_the_user_does_not_manage() {
    let base_url = serve_facebook_graph_api(Some(("123", "Test Page", "page-token")), "unused");

    let err = connect_facebook_page_at(
        &base_url,
        TEST_APP_ID,
        TEST_APP_SECRET,
        "short-lived-token",
        "999",
    )
    .unwrap_err();
    assert_eq!(err.code(), Code::PermissionDenied);
    assert_eq!(err.message(), "facebook_page_not_managed_by_user");
}

#[test]
fn connect_fails_when_user_manages_no_pages() {
    let base_url = serve_facebook_graph_api(None, "unused");

    let err = connect_facebook_page_at(
        &base_url,
        TEST_APP_ID,
        TEST_APP_SECRET,
        "short-lived-token",
        "123",
    )
    .unwrap_err();
    assert_eq!(err.code(), Code::PermissionDenied);
    assert_eq!(err.message(), "facebook_page_not_managed_by_user");
}

#[test]
fn post_event_instance_returns_the_new_posts_id_and_url() {
    let base_url = serve_facebook_graph_api(None, "123_456");
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "facebook_page": { "page_id": "123", "page_name": "Test Page", "access_token": "page-token" }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };
    let starts_at = Utc.with_ymd_and_hms(2099, 1, 1, 9, 0, 0).unwrap();
    let ends_at = Utc.with_ymd_and_hms(2099, 1, 1, 11, 0, 0).unwrap();
    let _ = (starts_at, ends_at); // formatting itself is covered by `sync_message_tests`.

    let (post_id, post_url) = post_event_instance_at(
        &base_url,
        &destination,
        &message("Test Event\n\nCome join us!", Some("https://example.com/event/abc")),
    )
    .expect("post should succeed");
    assert_eq!(post_id, "123_456");
    assert_eq!(post_url, "https://www.facebook.com/123_456");
}

#[test]
fn post_event_instance_fails_when_destination_is_not_configured() {
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({}),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let err = post_event_instance_at("http://127.0.0.1:1", &destination, &message("", None))
        .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "event_sync_destination_not_configured");
}

#[test]
fn post_post_at_returns_the_new_posts_id_and_url() {
    let base_url = serve_facebook_graph_api(None, "789_012");
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "facebook_page": { "page_id": "123", "page_name": "Test Page", "access_token": "page-token" }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let (post_id, post_url) = post_post_at(
        &base_url,
        &destination,
        &message("Test Post\n\nCheck this out!", None),
    )
    .expect("post should succeed");
    assert_eq!(post_id, "789_012");
    assert_eq!(post_url, "https://www.facebook.com/789_012");
}

#[test]
fn post_post_at_fails_when_destination_is_not_configured() {
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({}),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let err =
        post_post_at("http://127.0.0.1:1", &destination, &message("", None)).unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "sync_destination_not_configured");
}

#[test]
fn get_linked_instagram_business_account_returns_the_linked_account() {
    let base_url = serve_facebook_graph_api_instagram(Some(("ig-123", "ig_user")), "unused");

    let (id, username) =
        get_linked_instagram_business_account_at(&base_url, "page-token", "123")
            .expect("lookup should succeed");
    assert_eq!(id, "ig-123");
    assert_eq!(username, "ig_user");
}

#[test]
fn get_linked_instagram_business_account_fails_when_none_linked() {
    let base_url = serve_facebook_graph_api_instagram(None, "unused");

    let err = get_linked_instagram_business_account_at(&base_url, "page-token", "123")
        .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "instagram_no_linked_business_account");
}

#[test]
fn post_to_instagram_fails_fast_with_no_media() {
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "instagram_account": {
                "instagram_business_account_id": "ig-123",
                "username": "ig_user",
                "page_id": "123",
                "access_token": "page-token"
            }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let err = post_to_instagram_at("http://127.0.0.1:1", &destination, &message("Caption", None))
        .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "instagram_requires_media");
}

#[test]
fn post_to_instagram_publishes_and_returns_the_permalink() {
    let base_url = serve_facebook_graph_api_instagram(Some(("ig-123", "ig_user")), "media-999");
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "instagram_account": {
                "instagram_business_account_id": "ig-123",
                "username": "ig_user",
                "page_id": "123",
                "access_token": "page-token"
            }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };
    let sync_message = SyncMessage {
        text: "Check this out!".to_string(),
        link: None,
        media: vec!["https://example.com/photo.jpg".to_string()],
    };

    let (media_id, permalink) = post_to_instagram_at(&base_url, &destination, &sync_message)
        .expect("post should succeed");
    assert_eq!(media_id, "media-999");
    assert_eq!(
        permalink,
        "https://www.instagram.com/p/media-999-permalink/"
    );
}

#[test]
fn post_to_instagram_fails_when_destination_is_not_configured() {
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({}),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };
    let sync_message = SyncMessage {
        text: "Caption".to_string(),
        link: None,
        media: vec!["https://example.com/photo.jpg".to_string()],
    };

    let err = post_to_instagram_at("http://127.0.0.1:1", &destination, &sync_message)
        .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "sync_destination_not_configured");
}
