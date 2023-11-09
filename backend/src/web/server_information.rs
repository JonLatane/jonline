use super::RocketState;
use crate::rpcs::{get_server_configuration_proto, get_service_version};
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use rocket::{fs::NamedFile, http::Status, response::Redirect, routes, uri, Route, State};
use rocket_cache_response::CacheResponse;

lazy_static! {
    pub static ref INFORMATIONAL_PAGES: Vec<Route> =
        routes![info_shield, docs, documentation, protocol_docs];
}

#[rocket::get("/info_shield")]
async fn info_shield(state: &State<RocketState>) -> CacheResponse<Redirect> {
    let service_version = get_service_version().unwrap().version;

    let mut conn = state.pool.get().unwrap();
    let server_configuration = get_server_configuration_proto(&mut conn).unwrap();
    let server_info = server_configuration.server_info.as_ref().unwrap();
    let server_name = server_info.name.as_ref().unwrap();
    let colors = server_info.colors.as_ref().unwrap();
    let primary_color_int = colors.primary.unwrap();
    let nav_color_int = colors.navigation.unwrap();
    let mut primary_color = format!("{:x}", primary_color_int);
    while primary_color.len() < 6 {
        primary_color = format!("0{}", primary_color);
    }
    while primary_color.len() > 6 {
        primary_color = format!("{}", &primary_color[1..]);
    }
    let mut nav_color = format!("{:x}", nav_color_int);
    while nav_color.len() < 6 {
        nav_color = format!("0{}", nav_color);
    }
    while nav_color.len() > 6 {
        nav_color = format!("{}", &nav_color[1..]);
    }

    let encoded_server_name = utf8_percent_encode(&server_name, NON_ALPHANUMERIC).to_string();

    CacheResponse::NoStore(Redirect::temporary(format!(
        "https://img.shields.io/badge/{}-v{}-information?style=for-the-badge&labelColor={}&color={}",
        encoded_server_name.replace("-", "--"), service_version.replace("-", "--"), primary_color, nav_color
    )))
}

#[rocket::get("/documentation")]
fn documentation() -> Redirect {
    Redirect::to(uri!(docs))
}

#[rocket::get("/docs")]
fn docs() -> Redirect {
    Redirect::to(uri!(protocol_docs))
}

#[rocket::get("/docs/protocol")]
pub async fn protocol_docs() -> CacheResponse<Result<NamedFile, Status>> {
    docs_path("protocol.html").await
}

async fn docs_path(path: &str) -> CacheResponse<Result<NamedFile, Status>> {
    let result = match NamedFile::open(format!("opt/docs/{}", path)).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(format!("../docs/{}", path)).await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    };
    CacheResponse::Public {
        responder: result.map_err(|e| {
            log::error!("docs_path: {:?}", e);
            Status::NotFound
        }),
        max_age: 60,
        must_revalidate: false,
    }
}
