use tonic::{Response, Status};

use crate::conversions::ToProtoUser;
use crate::{models, protos};

pub fn get_current_user(user: models::User) -> Result<Response<protos::User>, Status> {
    println!("GetCurrentUser called for user {}, user_id={}", &user.username, user.id);
    Ok(Response::new(user.to_proto_user()))
}
