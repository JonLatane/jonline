use rocket::http::Status;
use rocket_cache_response::CacheResponse;

use super::{jonline_path_responder, JonlineResponder, JonlineSummary};

/// The Tamagui SPA is mounted both at `/` and at `/tamagui` (so it's reachable
/// the same way whether or not another frontend owns the site root). Routes
/// and handlers that derive meaning from path segments (e.g. extracting a
/// post/user/group id by index) are only written once, assuming no prefix, so
/// callers must normalize `origin.path()` through this function before doing
/// any segment-index-based parsing -- otherwise everything under `/tamagui`
/// resolves one segment off from what it should.
pub fn strip_tamagui_prefix(path: &str) -> String {
    match path.strip_prefix("/tamagui") {
        Some(rest) if rest.is_empty() => "/".to_string(),
        Some(rest) if rest.starts_with('/') => rest.to_string(),
        _ => path.to_string(),
    }
}

/// Whether a request path is under the "/tamagui" mount, as opposed to root.
/// Used to pick which of the two Next.js static exports (see `tamagui_path`)
/// a request should be served from.
pub fn is_tamagui_prefixed(path: &str) -> bool {
    path == "/tamagui" || path.starts_with("/tamagui/")
}

// Clean up text for tags like <meta property="og:title" content="$text" />
// so page rendering doesn't break.
macro_rules! sanitize_user_text {
    ($text:expr) => {
        $text.replace("\"", "\\\"").split('\n').next().unwrap_or("")
    };
}

macro_rules! html_sanitize_user_text {
    ($text:expr) => {
        $text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("\\", "&apos;")
            .split('\n')
            .next()
            .unwrap_or("")
    };
}

/// Render a page for the Tamagui frontend. Interpolates JonlineSummary data into
/// <title/>, <meta property="og:title"/>, etc. tags in the Tamagui Next.js template.
///
/// `is_tamagui_prefixed` selects which of the two Next.js static exports to read
/// from: Next bakes a single fixed `basePath` into a build's HTML/JS at build
/// time (see apps/next/next.config.js), so serving this app correctly at both
/// "/" and "/tamagui" requires two separate builds/directories -- "out" (no
/// basePath) and "out-tamagui" (basePath "/tamagui"), see apps/next/package.json's
/// "build:export". The `static_file_path` is also namespaced into the cache key
/// here, since `jonline_path_responder`'s cache is keyed purely by that path and
/// both variants otherwise share the same relative filenames.
pub async fn tamagui_path(
    static_file_path: &str,
    summary: Option<JonlineSummary>,
    is_tamagui_prefixed: bool,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    let (opt_dir, repo_dir) = if is_tamagui_prefixed {
        ("tamagui_web_tamagui", "out-tamagui")
    } else {
        ("tamagui_web", "out")
    };
    let cache_key = format!("{}/{}", opt_dir, static_file_path);
    let mut template = jonline_path_responder(
        &cache_key,
        &format!("opt/{}/{}", opt_dir, static_file_path),
        &format!("../frontends/tamagui/apps/next/{}/{}", repo_dir, static_file_path),
    )
    .await;

    match (summary, template.as_mut()) {
        (Some(summary), Some(template)) => {
            match summary.title {
                Some(title) => {
                    let updated_body = template
                        .inner
                        .replacen(
                            "Jonline Social Link",
                            sanitize_user_text!(title), //.replace("\"", "\\\"").split('\n').next().unwrap_or(""),
                            1,
                        )
                        .replacen(
                            "<title>Jonline</title>",
                            &format!("<title>{}</title>", html_sanitize_user_text!(title)),
                            1,
                        );
                    template.inner = updated_body;
                }
                None => (),
            };

            template.inner = template.inner.replacen(
                "A link from a fediverse community with events, posts, and realtime chat",
                sanitize_user_text!(summary.description.unwrap_or("".to_string())),
                1,
            );

            template.inner = template.inner.replacen(
                "<meta property=\"og:image\" content=\"/favicon.ico\"/>",
                summary.image.map_or("", |i| {
                    String::leak(format!("<meta property=\"og:image\" content=\"{}\"/>", i))
                }),
                1,
            );
        }
        _ => (),
    };
    CacheResponse::Public {
        responder: template.map_or(Err(Status::NotFound), |body| Ok(body)),
        max_age: 60,
        must_revalidate: false,
    }
}
