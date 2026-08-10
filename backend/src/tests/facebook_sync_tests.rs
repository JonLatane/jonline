//! Specs for `logic::facebook_sync`'s Graph API interaction correctness (token exchange, Page
//! lookup, posting), run against `factories::serve_facebook_graph_api` instead of the real
//! Facebook API. RPC-level permission/ownership handling is covered separately by
//! `event_sync_destination_rpc_tests`.

use chrono::{TimeZone, Utc};
use tonic::Code;

use crate::logic::{connect_facebook_page_at, post_event_instance_at};
use crate::models;
use crate::tests::factories::*;

/// `app_id`/`app_secret` are this Jonline server's own Facebook App credentials (now sourced from
/// `ServerConfiguration.federation_info.facebook_auth_config`, not an env var) -- their actual
/// value doesn't matter against a mock server, only that they're passed through.
const TEST_APP_ID: &str = "test-app-id";
const TEST_APP_SECRET: &str = "test-app-secret";

#[test]
fn connect_succeeds_for_a_page_the_user_manages() {
    let base_url = serve_facebook_graph_api(Some(("123", "Test Page", "page-token")), "unused");

    let connection =
        connect_facebook_page_at(&base_url, TEST_APP_ID, TEST_APP_SECRET, "short-lived-token", "123")
            .expect("connect should succeed");
    assert_eq!(connection.page_id, "123");
    assert_eq!(connection.page_name, "Test Page");
    assert_eq!(connection.access_token, "page-token");
}

#[test]
fn connect_fails_for_a_page_the_user_does_not_manage() {
    let base_url = serve_facebook_graph_api(Some(("123", "Test Page", "page-token")), "unused");

    let err =
        connect_facebook_page_at(&base_url, TEST_APP_ID, TEST_APP_SECRET, "short-lived-token", "999")
            .unwrap_err();
    assert_eq!(err.code(), Code::PermissionDenied);
    assert_eq!(err.message(), "facebook_page_not_managed_by_user");
}

#[test]
fn connect_fails_when_user_manages_no_pages() {
    let base_url = serve_facebook_graph_api(None, "unused");

    let err =
        connect_facebook_page_at(&base_url, TEST_APP_ID, TEST_APP_SECRET, "short-lived-token", "123")
            .unwrap_err();
    assert_eq!(err.code(), Code::PermissionDenied);
    assert_eq!(err.message(), "facebook_page_not_managed_by_user");
}

#[test]
fn post_event_instance_returns_the_new_posts_id_and_url() {
    let base_url = serve_facebook_graph_api(None, "123_456");
    let destination = models::EventSyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "facebook_page": { "page_id": "123", "page_name": "Test Page", "access_token": "page-token" }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };
    let starts_at = Utc.with_ymd_and_hms(2099, 1, 1, 9, 0, 0).unwrap();

    let (post_id, post_url) = post_event_instance_at(
        &base_url,
        &destination,
        &Some("Test Event".to_string()),
        &Some("Come join us!".to_string()),
        &None,
        starts_at,
    )
    .expect("post should succeed");
    assert_eq!(post_id, "123_456");
    assert_eq!(post_url, "https://www.facebook.com/123_456");
}

#[test]
fn post_event_instance_fails_when_destination_is_not_configured() {
    let destination = models::EventSyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({}),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };
    let starts_at = Utc.with_ymd_and_hms(2099, 1, 1, 9, 0, 0).unwrap();

    let err = post_event_instance_at(
        "http://127.0.0.1:1",
        &destination,
        &None,
        &None,
        &None,
        starts_at,
    )
    .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "event_sync_destination_not_configured");
}
