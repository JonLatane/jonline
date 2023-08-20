use tonic::{Response, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::ToProtoUser;
use crate::{media_lookup, models, protos};

pub fn get_current_user(
    user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Response<protos::User>, Status> {
    log::info!(
        "GetCurrentUser called for user {}, user_id={}",
        &user.username,
        user.id
    );

    let avatar: Option<models::MediaReference> = match user.avatar_media_id {
        None => None,
        Some(amid) => models::get_media_reference(amid, conn).ok(),
    };

    let result = user.to_proto(&None, &None, avatar.map(|mr| &media_lookup(&vec![mr])));
    // log::info!("GetCurrentUser::response={:?}", result);
    Ok(Response::new(result))
}
