use super::*;
use rocket::fs::*;
use rocket::*;
use rocket::http::Status;

use super::RocketState;

use rocket_cache_response::CacheResponse;

use crate::protos::*;
use crate::rpcs::get_server_configuration_proto;

#[rocket::get("/")]
pub async fn main_index(state: &State<RocketState>) -> CacheResponse<Result<NamedFile, Status>> {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration_proto(&mut conn).unwrap();

    match configuration.server_info.unwrap().web_user_interface() {
        WebUserInterface::FlutterWeb => flutter_index().await,
        _ => tamagui_index().await,
    }
}
