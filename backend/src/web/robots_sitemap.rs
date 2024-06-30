use rocket::http::uri::Host;
use rocket::*;

use super::RocketState;
use rocket::response::content::{RawJson, RawText, RawXml};

use rocket_cache_response::CacheResponse;

use crate::rpcs::get_server_configuration_proto;

lazy_static! {
    pub static ref SEO_PAGES: Vec<Route> = routes![robots, sitemap, manifest];
}
#[rocket::get("/robots.txt")]
async fn robots(state: &State<RocketState>, host: &Host<'_>) -> CacheResponse<RawText<String>> {
    let domain = host.domain();
    let mut conn = state.pool.get().unwrap();
    let _configuration = get_server_configuration_proto(&mut conn).unwrap();
    let response = RawText(
        format!(
            "User-agent: *
Allow: /

Sitemap: https://{}/sitemap.xml
",
            domain
        )
        .to_string(),
    );

    CacheResponse::Public {
        responder: response,
        max_age: 3600,
        must_revalidate: false,
    }
}

#[rocket::get("/sitemap.xml")]
async fn sitemap(state: &State<RocketState>, host: &Host<'_>) -> CacheResponse<RawXml<String>> {
    let domain = host.domain();
    let mut conn = state.pool.get().unwrap();
    let _configuration = get_server_configuration_proto(&mut conn).unwrap();

    let response = RawXml(
        format!(
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"> 
    <url>
        <loc>https://{}/</loc>
    </url>
    <url>
        <loc>https://{}/posts</loc> 
    </url>
    <url>
        <loc>https://{}/events</loc> 
    </url>
    <url>
        <loc>https://{}/people</loc> 
    </url>
    <url>
        <loc>https://{}/about</loc> 
    </url>
    <url>
        <loc>https://{}/about_jonline</loc> 
    </url>
    <url>
        <loc>https://{}/flutter</loc> 
    </url>
</urlset>
",
            domain, domain, domain, domain, domain, domain, domain
        )
        .to_string(),
    );

    CacheResponse::Public {
        responder: response,
        max_age: 3600,
        must_revalidate: false,
    }
}

#[rocket::get("/manifest.json")]
async fn manifest(state: &State<RocketState>, host: &Host<'_>) -> CacheResponse<RawJson<String>> {
    // let domain = host.domain();
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration_proto(&mut conn).unwrap();

    let server_name = configuration
        .clone()
        .server_info
        .map(|i| i.name)
        .flatten()
        .unwrap_or("Jonline".to_string());
    let server_logo_id = configuration
        .server_info
        .as_ref()
        .map(|i| i.logo.as_ref())
        .flatten()
        .map(|l| l.square_media_id.clone())
        .flatten();
    let server_logo = server_logo_id.map(|id| format!("/media/{}", id));
    let primary_color_int = configuration
        .server_info
        .map(|i| i.colors)
        .flatten()
        .map(|c| c.primary)
        .flatten()
        .unwrap_or(424242);
    let primary_color = &format!("{:x}", primary_color_int)[2..8];
    // let server_logo_type
    let response = RawJson(
        format!(
            "{{
  \"name\": \"{}\",
  \"theme_color\": \"#{}CC\",
  \"start_url\": \"/\",
  \"display\": \"standalone\",
  \"orientation\": \"portrait-primary\",
  \"icons\": [
    {{
      \"src\": \"favicon.ico\",
      \"sizes\": \"500x500\",
      \"type\": \"image&#x2F;png\"
    }}
  ]
}}
",
            server_name,
            primary_color,
            // server_logo.unwrap_or("/favicon.ico".to_string())
        )
        .to_string(),
    );

    CacheResponse::Public {
        responder: response,
        max_age: 3600,
        must_revalidate: false,
    }
}
