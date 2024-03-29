use diesel::NotFound;
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::users;

use crate::rpcs::validations::*;

pub fn delete_user(
    request: User,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    validate_user(&request)?;

    let self_delete = request.id == current_user.id.to_proto_id();
    let admin = match validate_permission(&Some(current_user), Permission::Admin) {
        Ok(_) => true,
        Err(e) => if !self_delete {
            return Err(e);
        } else {
            false
        }
    };
    log::info!("self_delete: {}, admin: {}", self_delete, admin);

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
