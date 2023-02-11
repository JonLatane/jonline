use tonic::{Response, Status};

use crate::conversions::ToProtoUser;
use crate::{models, protos};

pub fn get_current_user(user: models::User) -> Result<Response<protos::User>, Status> {
    log::info!("GetCurrentUser called for user {}, user_id={}", &user.username, user.id);
    let result = user.to_proto();
    // log::info!("GetCurrentUser::response={:?}", result);
    Ok(Response::new(result))
}
