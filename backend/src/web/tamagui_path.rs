use rocket::http::Status;
use rocket_cache_response::CacheResponse;

use super::{jonline_path_responder, JonlineResponder, JonlineSummary};

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
pub async fn tamagui_path(
    static_file_path: &str,
    summary: Option<JonlineSummary>,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    let mut template = jonline_path_responder(
        static_file_path,
        &format!("opt/tamagui_web/{}", static_file_path),
        &format!("../frontends/tamagui/apps/next/out/{}", static_file_path),
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
