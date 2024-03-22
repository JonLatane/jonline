use bcrypt::{hash, DEFAULT_COST};
use diesel::NotFound;
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::users;

use crate::rpcs::validations::*;

pub fn reset_password(
    request: ResetPasswordRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let user_id = match &request.user_id {
        Some(ref id) => id.to_db_id_or_err("user_id")?,
        None => current_user.id,
    };
    let self_delete = user_id == current_user.id;
    let admin = match validate_permission(&Some(current_user), Permission::Admin) {
        Ok(_) => true,
        Err(e) => {
            if !self_delete {
                return Err(e);
            } else {
                false
            }
        }
    };
    log::info!("self_delete: {}, admin: {}", self_delete, admin);

    let hashed_password = hash(&request.password, DEFAULT_COST).unwrap();

    let db_result = update(users::table.find(user_id))
        .set(users::password_salted_hash.eq(hashed_password))
        .execute(conn);

    let result = match db_result {
        Ok(size) if size == 0 => Err(Status::new(Code::NotFound, "user_not_found")),
        Ok(_) => Ok(()),
        Err(NotFound) => Err(Status::new(Code::NotFound, "user_not_found")),
        Err(e) => {
            log::error!("Error deleting user: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    };
    log::info!(
        "ResetPassword::request: {:?}, result: {:?}",
        ResetPasswordRequest {
            password: "<redacted>".to_string(),
            ..request
        },
        result
    );

    result
}
