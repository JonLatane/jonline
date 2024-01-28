use rocket::http::Status;
use rocket_cache_response::CacheResponse;

use super::{jonline_path_responder, JonlineResponder, JonlineSummary};

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
                    let updated_body = template.inner.replacen("Jonline Social Link", &title, 1);
                    template.inner = updated_body;
                }
                None => (),
            };

            template.inner = template.inner.replacen(
                "A link from a fediverse community with events, posts, and realtime chat",
                &summary.description.unwrap_or("".to_string()),
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
