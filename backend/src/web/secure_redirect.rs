use std::path::PathBuf;

use rocket::{get, response::Redirect, State};

use super::{headers::HostHeader, RocketState};
use crate::rpcs::get_server_configuration;

#[get("/<path..>")]
pub fn redirect_to_secure(state: &State<RocketState>, host: HostHeader<'_>, path: PathBuf) -> Redirect {
    let configured_backend_domain = configured_backend_domain(state, host);
    let redirect_url = format!(
        "https://{}/{}",
        configured_backend_domain,
        path.to_string_lossy()
    );
    // format!("Hello from {}. Redirecting to {}", domain, redirect_url)
    Redirect::to(redirect_url)
}

pub fn configured_backend_domain(state: &State<RocketState>, host: HostHeader<'_>) -> String {
    let mut conn = state.pool.get().unwrap();
    let configured_backend_domain = match get_server_configuration(&mut conn)
        .unwrap()
        .default_client_domain
    {
        Some(domain) if domain != "" => domain,
        _ => host.0.split(":").next().unwrap().to_string(),
    };
    configured_backend_domain
}
