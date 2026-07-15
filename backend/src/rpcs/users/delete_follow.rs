use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validations::*;
use crate::schema::follows;

pub fn delete_follow(
    request: Follow,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    if request.user_id != current_user.id.to_proto_id()
        && request.target_user_id != current_user.id.to_proto_id()
    {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }
    let user_id = request.user_id.to_db_id_or_err("user_id")?;
    let target_user_id = request.target_user_id.to_db_id_or_err("target_user_id")?;
    let existing_follow = follows::table
        .select(follows::all_columns)
        .filter(follows::user_id.eq(user_id))
        .filter(follows::target_user_id.eq(target_user_id))
        .first::<models::Follow>(conn)
        .map_err(|_| Status::new(Code::NotFound, "follow_not_found"))?;

    match diesel::delete(follows::table)
        .filter(follows::target_user_id.eq(target_user_id))
        .filter(follows::user_id.eq(user_id))
        .execute(conn)
    {
        Ok(_) => {
            existing_follow.update_related_counts(conn)?;
            Ok(())
        }
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
