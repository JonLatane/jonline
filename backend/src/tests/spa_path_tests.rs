//! `web::spa_path::SpaPath`: the SPA catch-all path guard must accept a short Bluesky post URL (a final segment
//! ending in `:`), which Rocket's own `PathBuf` guard rejects, without giving up the traversal protections.

use std::path::{Path, PathBuf};

use rocket::{get, http::Status, local::blocking::Client, routes};

use crate::web::spa_path::{SpaPath, path_from_segments};

#[get("/<file..>")]
fn spa_path_route(file: SpaPath) -> String {
    file.0.to_string_lossy().to_string()
}

// Rocket's own guard, as the catch-alls used before -- here to pin down the behavior being worked around.
#[get("/<file..>")]
fn path_buf_route(file: PathBuf) -> String {
    file.to_string_lossy().to_string()
}

fn client() -> Client {
    Client::tracked(rocket::build().mount("/", routes![spa_path_route]))
        .expect("valid rocket instance")
}

// Its own instance: on a shared one the `PathBuf` route would just forward to `spa_path_route`.
fn path_buf_client() -> Client {
    Client::tracked(rocket::build().mount("/", routes![path_buf_route]))
        .expect("valid rocket instance")
}

const BLUESKY_SHORT: &str = "~did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky:";

#[test]
fn accepts_a_short_bluesky_url_ending_in_a_colon() {
    let client = client();
    let response = client.get(format!("/{}", BLUESKY_SHORT)).dispatch();
    assert_eq!(response.status(), Status::Ok);
    assert_eq!(response.into_string().unwrap(), BLUESKY_SHORT);
}

#[test]
fn rockets_own_path_buf_guard_rejects_it_which_is_why_spa_path_exists() {
    let client = path_buf_client();
    let response = client.get(format!("/{}", BLUESKY_SHORT)).dispatch();
    assert_eq!(response.status(), Status::UnprocessableEntity);
}

#[test]
fn accepts_the_other_short_forms_too() {
    let client = client();
    for segment in [
        "~109876543210@mastodon:mastodon.social",
        ":did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky:",
        "~4rAfoSKAuJo",
        "elm/~did:plc:wv5mhfadfpt6wmvoxedgqzyw~3mte7ozu3qc2s@bluesky:",
    ] {
        let response = client.get(format!("/{}", segment)).dispatch();
        assert_eq!(response.status(), Status::Ok, "{}", segment);
        assert_eq!(response.into_string().unwrap(), segment);
    }
}

#[test]
fn keeps_the_traversal_protections() {
    let client = client();
    // Dotfiles, and a leading `*`/trailing `<`/`>`, are still refused (they forward, so nothing matches).
    for path in ["/.env", "/a/.git/config", "/*star", "/a<", "/a>", "/a%2Fb"] {
        let response = client.get(path).dispatch();
        assert_ne!(response.status(), Status::Ok, "{}", path);
    }
}

#[test]
fn path_from_segments_matches_path_bufs_rules_except_for_a_trailing_colon() {
    assert_eq!(
        path_from_segments(["a", "b", "c.js"]).unwrap(),
        Path::new("a/b/c.js")
    );
    assert_eq!(
        path_from_segments(["a", "..", "b"]).unwrap(),
        Path::new("b")
    );
    assert_eq!(
        path_from_segments(["x@bluesky:"]).unwrap(),
        Path::new("x@bluesky:")
    );
    assert!(path_from_segments([".hidden"]).is_err());
    assert!(path_from_segments(["a", "*b"]).is_err());
    assert!(path_from_segments(["a>"]).is_err());
    assert!(path_from_segments(["a<"]).is_err());
    assert!(path_from_segments(["a/b"]).is_err());
}
