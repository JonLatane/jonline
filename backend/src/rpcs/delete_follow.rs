use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::follows;

pub fn delete_follow(
    request: Follow,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    if request.user_id != current_user.id.to_proto_id() {
        validate_permission(&current_user, Permission::Admin)?;
    }
    let existing_follow = follows::table
        .select(follows::all_columns)
        .filter(follows::user_id.eq(request.user_id.to_db_id().unwrap()))
        .filter(follows::target_user_id.eq(request.target_user_id.to_db_id().unwrap()))
        .first::<models::Follow>(conn)
        .map_err(|_| Status::new(Code::NotFound, "follow_not_found"))?;

    match diesel::delete(follows::table)
        .filter(follows::target_user_id.eq(request.target_user_id.to_db_id().unwrap()))
        .filter(follows::user_id.eq(request.user_id.to_db_id().unwrap()))
        .execute(conn)
    {
        Ok(_) => {
            existing_follow.update_related_counts(conn)?;
            Ok(())
        },
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
