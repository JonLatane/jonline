//! Specs for `logic::mastodon_sync`'s REST API interaction correctness (credential verification,
//! posting), run against `factories::serve_mastodon_api` instead of a real Mastodon instance.
//! RPC-level permission/ownership handling is covered separately by `sync_destination_rpc_tests`/
//! `post_sync_rpc_tests`.

use tonic::Code;

use crate::logic::{post_status_at, verify_credentials_at, SyncMessage};
use crate::models;
use crate::tests::factories::*;

#[test]
fn verify_credentials_returns_the_username_for_a_valid_token() {
    let base_url = serve_mastodon_api("test_user", true, true, "1", "https://unused");

    let username =
        verify_credentials_at(&base_url, "valid-token").expect("verify should succeed");
    assert_eq!(username, "test_user");
}

#[test]
fn verify_credentials_fails_for_an_invalid_token() {
    let base_url = serve_mastodon_api("test_user", false, true, "1", "https://unused");

    let err = verify_credentials_at(&base_url, "invalid-token").unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "mastodon_token_invalid");
}

fn message(text: &str) -> SyncMessage {
    SyncMessage {
        text: text.to_string(),
        link: None,
        media: vec![],
    }
}

#[test]
fn post_status_returns_the_new_statuss_id_and_url() {
    let base_url = serve_mastodon_api(
        "test_user",
        true,
        true,
        "12345",
        "https://mastodon.social/@test_user/12345",
    );
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "mastodon_account": {
                "instance_host": "mastodon.social",
                "username": "test_user",
                "access_token": "test-token"
            }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let (id, url) = post_status_at(&base_url, &destination, &message("Hello, Mastodon!"))
        .expect("post should succeed");
    assert_eq!(id, "12345");
    assert_eq!(url, "https://mastodon.social/@test_user/12345");
}

#[test]
fn post_status_fails_when_the_api_rejects_the_post() {
    let base_url = serve_mastodon_api("test_user", true, false, "12345", "https://unused");
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({
            "mastodon_account": {
                "instance_host": "mastodon.social",
                "username": "test_user",
                "access_token": "test-token"
            }
        }),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let err = post_status_at(&base_url, &destination, &message("Too long..."))
        .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "mastodon_post_failed");
}

#[test]
fn post_status_fails_when_destination_is_not_configured() {
    let destination = models::SyncDestination {
        id: 1,
        user_id: 1,
        configuration: serde_json::json!({}),
        created_at: std::time::SystemTime::now(),
        updated_at: None,
    };

    let err = post_status_at("http://127.0.0.1:1", &destination, &message("Hello")).unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
    assert_eq!(err.message(), "sync_destination_not_configured");
}
