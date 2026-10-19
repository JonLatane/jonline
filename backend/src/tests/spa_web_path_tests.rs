//! Link-preview metadata (`web::spa_web_path`) is user-controlled text interpolated into a page's `<head>`: it must
//! never be able to leave the `<meta content="…">` attribute (or `<title>`) it's written into.

use rocket::{get, http::Status, local::blocking::Client, routes};
use rocket_cache_response::CacheResponse;

use crate::web::{RellmResponder, RellmSummary, SpaApp, meta_text, spa_web_path};

const HOSTILE_TITLE: &str = "\" /><script>window.__pwned=1</script><meta x=\"";
const HOSTILE_DESCRIPTION: &str = "desc \"/><img src=x onerror=window.__pwned2=1>";
const HOSTILE_IMAGE: &str = "/media/x\" onerror=\"window.__pwned3=1";

#[get("/hostile")]
async fn hostile() -> CacheResponse<Result<RellmResponder, Status>> {
    spa_web_path(
        SpaApp::Elm,
        "index.html",
        Some(RellmSummary {
            title: Some(HOSTILE_TITLE.to_string()),
            description: Some(HOSTILE_DESCRIPTION.to_string()),
            image: Some(HOSTILE_IMAGE.to_string()),
        }),
        false,
    )
    .await
}

#[get("/plain")]
async fn plain() -> CacheResponse<Result<RellmResponder, Status>> {
    spa_web_path(
        SpaApp::Elm,
        "index.html",
        Some(RellmSummary {
            title: Some("Fish & Chips | Post Details".to_string()),
            description: Some("First line\nsecond line".to_string()),
            image: Some("/media/abc".to_string()),
        }),
        false,
    )
    .await
}

fn body_of(path: &str) -> String {
    let client = Client::tracked(rocket::build().mount("/", routes![hostile, plain]))
        .expect("valid rocket instance");
    let response = client.get(path.to_string()).dispatch();
    assert_eq!(response.status(), Status::Ok, "{}", path);
    response.into_string().expect("a body")
}

#[test]
fn meta_text_escapes_everything_that_can_leave_an_attribute_or_start_markup() {
    assert_eq!(meta_text("a & b"), "a &amp; b");
    assert_eq!(
        meta_text("<b>\"x\"</b>"),
        "&lt;b&gt;&quot;x&quot;&lt;/b&gt;"
    );
    assert_eq!(meta_text("it's"), "it&#39;s");
    // A backslash is not an escape in HTML, so it is left alone (and `"` still becomes `&quot;`).
    assert_eq!(meta_text("a\\\"b"), "a\\&quot;b");
}

#[test]
fn meta_text_keeps_only_the_first_line() {
    assert_eq!(meta_text("one\ntwo"), "one");
    assert_eq!(meta_text(""), "");
}

#[test]
fn a_hostile_title_description_and_image_cannot_inject_markup() {
    let body = body_of("/hostile");
    // None of the injected tags/attributes exist as markup...
    assert!(!body.contains("<script>window.__pwned"), "{}", body);
    assert!(!body.contains("<img src=x"), "{}", body);
    assert!(!body.contains("\" onerror="), "{}", body);
    // ...they're all inert text inside the attributes, in the very tags the template already had.
    assert!(body.contains("&lt;script&gt;window.__pwned=1&lt;/script&gt;"));
    assert!(body.contains(
        "<meta property=\"og:image\" content=\"/media/x&quot; onerror=&quot;window.__pwned3=1\"/>"
    ));
    assert!(body.contains("<title>&quot; /&gt;&lt;script&gt;"));
}

#[test]
fn an_ordinary_summary_renders_as_before() {
    let body = body_of("/plain");
    assert!(body.contains("<title>Fish &amp; Chips | Post Details</title>"));
    assert!(
        body.contains("<meta property=\"og:title\" content=\"Fish &amp; Chips | Post Details\" />")
    );
    assert!(body.contains("content=\"First line\""));
    assert!(body.contains("<meta property=\"og:image\" content=\"/media/abc\"/>"));
}
