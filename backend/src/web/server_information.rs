use super::RocketState;
use crate::rpcs::{get_server_configuration, get_service_version};
use rocket::{response::Redirect, routes, Route, State};
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};

lazy_static! {
    pub static ref INFORMATIONAL_PAGES: Vec<Route> = routes![info_shield];
}

#[rocket::get("/info_shield")]
async fn info_shield(state: &State<RocketState>) -> Redirect {
    let service_version = get_service_version().unwrap().version;

    let mut conn = state.pool.get().unwrap();
    let server_configuration = get_server_configuration(&mut conn).unwrap();
    let server_name = server_configuration
        .server_info
        .map(|x| x.name)
        .flatten()
        .unwrap_or("Jonline".to_string());
    let encoded_server_name = utf8_percent_encode(&server_name, NON_ALPHANUMERIC);

    Redirect::temporary(format!(
        "https://img.shields.io/badge/{}-{}-informational?style=for-the-badge",
        encoded_server_name, service_version
    ))
}
