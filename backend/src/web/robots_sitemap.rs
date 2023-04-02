use rocket::*;

use super::{HostHeader, RocketState};
use rocket::response::content::{RawText, RawXml};

use rocket_cache_response::CacheResponse;

use crate::rpcs::get_server_configuration;

lazy_static! {
    pub static ref SEO_PAGES: Vec<Route> = routes![robots, sitemap];
}
#[rocket::get("/robots.txt")]
pub async fn robots(
    state: &State<RocketState>,
    host: HostHeader<'_>,
) -> CacheResponse<RawText<String>> {
    let domain = host.0.split(":").next().unwrap();
    let mut conn = state.pool.get().unwrap();
    let _configuration = get_server_configuration(&mut conn).unwrap();
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
pub async fn sitemap(
    state: &State<RocketState>,
    host: HostHeader<'_>,
) -> CacheResponse<RawXml<String>> {
    let domain = host.0.split(":").next().unwrap();
    let mut conn = state.pool.get().unwrap();
    let _configuration = get_server_configuration(&mut conn).unwrap();

    let response = RawXml(
        format!(
            "
<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"> 
    <url>
    <loc>https://{}/</loc>
    </url>
    <url>
    <loc>https://{}/people</loc> 
    </url>
    <url>Ø
    <loc>https://{}/flutter</loc> 
    </url>
</urlset>
    ",
            domain, domain, domain
        )
        .to_string(),
    );

    CacheResponse::Public {
        responder: response,
        max_age: 3600,
        must_revalidate: false,
    }
}
