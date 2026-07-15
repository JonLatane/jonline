use rocket::http::Status;
use rocket_cache_response::CacheResponse;

use crate::protos::{ServerInfo, WebUserInterface};

use super::{jonline_path_responder, JonlineResponder, JonlineSummary};

/// Which single-page-app should render a given request: the Tamagui
/// (React/Next.js) frontend or the Elm frontend. Both apps are mounted at the
/// same set of paths (see `SPA_PAGES` in `spa_pages.rs`) three times over --
/// unprefixed ("/"), "/tamagui", and "/elm" -- so a request's path alone
/// doesn't always determine which app to render; unprefixed requests fall
/// back to the server's configured `WebUserInterface` (see `root_app`).
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub enum SpaApp {
    Tamagui,
    Elm,
}

/// Which app's prefix (if any) a request path is under.
pub fn spa_prefix(path: &str) -> Option<SpaApp> {
    if path == "/tamagui" || path.starts_with("/tamagui/") {
        Some(SpaApp::Tamagui)
    } else if path == "/elm" || path.starts_with("/elm/") {
        Some(SpaApp::Elm)
    } else {
        None
    }
}

/// Which app an *unprefixed* ("/"-rooted) request should render, per the
/// server's configured `WebUserInterface`. Only `ElmSpa` opts into the Elm
/// frontend; every other configuration (including ones with no SPA of their
/// own, like Flutter) renders Tamagui, at least for now.
pub fn root_app(server_info: &ServerInfo) -> SpaApp {
    match server_info.web_user_interface() {
        WebUserInterface::ElmSpa => SpaApp::Elm,
        _ => SpaApp::Tamagui,
    }
}

/// Strips whichever app prefix (if any) a request path is under, so route
/// handlers that derive meaning from path segments (e.g. extracting a
/// post/user/group id by index) can be written once, assuming no prefix --
/// otherwise everything under "/tamagui" or "/elm" resolves one segment off
/// from what it should.
pub fn strip_spa_prefix(path: &str) -> String {
    let prefix = match spa_prefix(path) {
        Some(SpaApp::Tamagui) => "/tamagui",
        Some(SpaApp::Elm) => "/elm",
        None => return path.to_string(),
    };
    match path.strip_prefix(prefix) {
        Some(rest) if rest.is_empty() => "/".to_string(),
        Some(rest) if rest.starts_with('/') => rest.to_string(),
        _ => path.to_string(),
    }
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

/// The link-preview summary shown for each SPA's home page. Shared so both
/// apps' home routes (and the "/" root dispatcher in `main_index.rs`) render
/// identical text, regardless of which app ends up serving the request.
pub fn index_summary(server_name: &str, server_logo: Option<String>) -> Option<JonlineSummary> {
    Some(JonlineSummary {
        title: Some(format!("Latest | {}", server_name)),
        description: Some("Posts and Events from a Jonline community".to_string()),
        image: server_logo.or(Some("/favicon.ico".to_string())),
    })
}

/// Render a page for either SPA frontend. Interpolates `JonlineSummary` data
/// into `<title/>`, `<meta property="og:title"/>`, etc. tags in the app's
/// HTML template -- both apps' templates use the same placeholder strings
/// (see `frontends/tamagui/apps/next/pages/_document.tsx`'s defaults and
/// `frontends/elm-spa/public/index.html`'s `<head>`), so the replacement
/// logic below is shared between them.
///
/// `tamagui_html_path` selects which static file to serve when `app` is
/// `Tamagui` (Next statically exports one HTML file per route); Elm is a
/// true SPA that always serves the same `index.html` regardless of route, so
/// this argument is ignored when `app` is `Elm`.
///
/// `is_tamagui_prefixed` selects which of the two Tamagui Next.js static
/// exports to read from: Next bakes a single fixed `basePath` into a
/// build's HTML/JS at build time (see apps/next/next.config.js), so serving
/// Tamagui correctly at both "/" and "/tamagui" requires two separate
/// builds/directories -- "out" (no basePath) and "out-tamagui" (basePath
/// "/tamagui"), see apps/next/package.json's "build:export". This is `true`
/// only when the request's literal path is under "/tamagui" -- an unprefixed
/// request that resolves to `SpaApp::Tamagui` via `root_app` must still use
/// the no-basePath "out" build, since it's served unprefixed.
pub async fn spa_web_path(
    app: SpaApp,
    tamagui_html_path: &str,
    summary: Option<JonlineSummary>,
    is_tamagui_prefixed: bool,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    let mut template = match app {
        SpaApp::Tamagui => {
            let (opt_dir, repo_dir) = if is_tamagui_prefixed {
                ("tamagui_web_tamagui", "out-tamagui")
            } else {
                ("tamagui_web", "out")
            };
            let cache_key = format!("{}/{}", opt_dir, tamagui_html_path);
            jonline_path_responder(
                &cache_key,
                &format!("opt/{}/{}", opt_dir, tamagui_html_path),
                &format!(
                    "../frontends/tamagui/apps/next/{}/{}",
                    repo_dir, tamagui_html_path
                ),
            )
            .await
        }
        SpaApp::Elm => {
            jonline_path_responder(
                "elm_web/index.html",
                "opt/elm_web/index.html",
                "../frontends/elm-spa/public/index.html",
            )
            .await
        }
    };

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
