use super::*;
use rocket::http::{ContentType, MediaType};
use rocket::{State, http::Status};

use super::RocketState;

use rocket_cache_response::CacheResponse;
use std::fs;
use crate::protos::*;
use crate::rpcs::get_server_configuration_proto;
use std::str::FromStr;

#[rocket::get("/")]
pub async fn main_index(state: &State<RocketState>) -> CacheResponse<Result<JonlineResponder, Status>> {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration_proto(&mut conn).unwrap();

    match configuration.server_info.unwrap().web_user_interface() {
        WebUserInterface::FlutterWeb => {
            let result = match fs::read_to_string("opt/flutter_web/index.html") {
                Ok(file) => Ok(file),
                Err(_) => match fs::read_to_string("../frontends/flutter/build/web/index.html") {
                    Ok(file) => Ok(file),
                    Err(e) => Err(e),
                },
            };
            let result_data = result.map(|data| JonlineResponder {
                inner: data,
                content_type: ContentType(MediaType::from_str("text/html").unwrap()),
            });
            // Ok(JonlineResponder {
            //     inner: result,
            //     content_type: ContentType(MediaType::from_str("text/html").unwrap()),
            // })
            CacheResponse::Public {
                responder: result_data.map_err(|e| {
                    log::info!("flutter: {:?}", e);
                    Status::NotFound
                }),
                max_age: 60,
                must_revalidate: false,
            }
            // flutter_index().await
        },
        _ => index().await,
    }
}
