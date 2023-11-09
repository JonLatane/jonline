use rocket::*;
use rocket::http::uri::Host;

use super::RocketState;
use rocket::response::content::{RawText, RawXml};

use rocket_cache_response::CacheResponse;

use crate::rpcs::get_server_configuration_proto;

lazy_static! {
    pub static ref SEO_PAGES: Vec<Route> = routes![robots, sitemap];
}
#[rocket::get("/robots.txt")]
async fn robots(
    state: &State<RocketState>,
    host: &Host<'_>,
) -> CacheResponse<RawText<String>> {
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
async fn sitemap(
    state: &State<RocketState>,
    host: &Host<'_>,
) -> CacheResponse<RawXml<String>> {
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
