use diesel::NotFound;
use diesel::*;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::users;

use super::validations::*;

pub fn delete_user(
    request: User,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    validate_user(&request)?;

    let self_delete = request.id == current_user.id.to_proto_id();
    let mut admin = false;
    if !self_delete {
        validate_any_permission(
            &current_user,
            vec![Permission::Admin],
        )?;
    }
    match validate_permission(&current_user, Permission::Admin) {
        Ok(_) => admin = true,
        Err(_) => {}
    };
    log::info!(
        "self_delete: {}, admin: {}",
        self_delete, admin
    );

    let db_result = delete(users::table.find(request.id.to_db_id_or_err("id")?)).execute(conn);

    let result = match db_result {
        Ok(size) if size == 0 => Err(Status::new(Code::NotFound, "user_not_found")),
        Ok(_) => Ok(()),
        Err(NotFound) => Err(Status::new(Code::NotFound, "user_not_found")),
        Err(e) => {
            log::error!("Error deleting user: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    };
    log::info!("DeleteUser::request: {:?}, result: {:?}", request, result);

    result
}
