use diesel::NotFound;
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::media;

use super::validations::*;

pub fn delete_media(
    request: Media,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let affected_media = media::table
        .filter(media::id.eq(request.id.to_db_id_or_err("id")?))
        .get_result::<models::Media>(conn)
        .optional()
        .map_err(|e| {
            log::error!("Error finding media: {:?}", e);
            Status::new(Code::Internal, "media_not_found")
        })?;

    if affected_media.is_none() {
        return Err(Status::new(Code::NotFound, "media_not_found"));
    }

    let self_delete = affected_media.unwrap().user_id == Some(current_user.id);
    let mut admin = false;
    if !self_delete {
        validate_any_permission(&current_user, vec![Permission::Admin])?;
    }
    match validate_permission(&current_user, Permission::Admin) {
        Ok(_) => admin = true,
        Err(_) => {}
    };
    log::info!("self_delete: {}, admin: {}", self_delete, admin);

    if !(self_delete | admin) {
        return Err(Status::new(Code::PermissionDenied, "not_your_media"));
    }

    let db_result = update(media::table.find(request.id.to_db_id_or_err("id")?))
        .set(media::user_id.eq(None::<i64>))
        .execute(conn);

    let result = match db_result {
        Ok(size) if size == 0 => Err(Status::new(Code::NotFound, "media_not_found")),
        Ok(_) => Ok(()),
        Err(NotFound) => Err(Status::new(Code::NotFound, "media_not_found")),
        Err(e) => {
            log::error!("Error deleting media: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    };
    log::info!("DeleteUser::request: {:?}, result: {:?}", request, result);

    result
}
