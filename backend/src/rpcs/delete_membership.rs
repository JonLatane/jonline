use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::memberships;

pub fn delete_membership(
    request: Membership,
    current_user: models::User,
    conn: &PgPooledConnection,
) -> Result<(), Status> {
    validate_membership(&request, OperationType::Create)?;

    let user_membership = match memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(current_user.id))
        .filter(memberships::group_id.eq(request.group_id.to_db_id_or_err("group_id")?))
        .first::<models::Membership>(conn)
    {
        Ok(membership) => Some(membership),
        Err(diesel::NotFound) => None,
        Err(_) => return Err(Status::new(Code::Internal, "data_error")),
    };

    let self_update = request.user_id == current_user.id.to_proto_id();
    if !self_update {
        validate_group_or_general_admin(&current_user, &user_membership)?;
    }

    match diesel::delete(memberships::table)
        .filter(memberships::group_id.eq(request.group_id.to_db_id().unwrap()))
        .filter(memberships::user_id.eq(request.user_id.to_db_id().unwrap()))
        .execute(conn)
    {
        Ok(_) => {
            user_membership
                .map(|m| m.update_related_counts(conn))
                .transpose()?;
            Ok(())
        }
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
