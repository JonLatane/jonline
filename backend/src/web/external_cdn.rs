use rocket::{routes, Route, State};
use rocket_cache_response::CacheResponse;
use rocket::http::uri::Host;

use super::RocketState;
use crate::{protos::ExternalCdnConfig, rpcs::get_server_configuration};

lazy_static! {
    pub static ref EXTERNAL_CDN_PAGES: Vec<Route> = routes![backend_host, frontend_host];
}

#[rocket::get("/backend_host")]
async fn backend_host(state: &State<RocketState>, host: &Host<'_>) -> CacheResponse<String> {
    let configured_backend_domain = configured_backend_domain(state, host);
    CacheResponse::NoStore(configured_backend_domain)
}

#[rocket::get("/frontend_host")]
async fn frontend_host(state: &State<RocketState>, host: &Host<'_>) -> CacheResponse<String> {
    let configured_backend_domain = configured_backend_domain(state, host);
    CacheResponse::NoStore(configured_backend_domain)
}

pub fn configured_backend_domain(state: &State<RocketState>, host: &Host<'_>) -> String {
    match external_cdn_config(state).map(|c| c.backend_host) {
        Some(domain) if domain != "" => domain,
        _ => host.domain().to_string(),
    }
}

pub fn configured_frontend_domain(state: &State<RocketState>, host: &Host<'_>) -> String {
    match external_cdn_config(state).map(|c| c.frontend_host) {
        Some(domain) if domain != "" => domain,
        _ => host.domain().to_string(),
    }
}

pub fn external_cdn_config(state: &State<RocketState>) -> Option<ExternalCdnConfig> {
    let mut conn = state.pool.get().unwrap();
    get_server_configuration(&mut conn)
        .unwrap()
        .external_cdn_config
}
