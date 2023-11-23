use diesel::*;
use tonic::{Code, Status};

use crate::rpcs::validations::*;
use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::memberships;

pub fn delete_membership(
    request: Membership,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    validate_membership(&request, OperationType::Create)?;

    let (group, membership) = models::get_group_and_membership(
        request.group_id.to_db_id_or_err("group_id")?,
        Some(current_user.id),
        conn,
    )?;

    let self_update = request.user_id == current_user.id.to_proto_id();
    if !self_update {
        validate_group_admin(&Some(current_user), &group, &membership.as_ref())?;
    }

    match diesel::delete(memberships::table)
        .filter(memberships::group_id.eq(request.group_id.to_db_id().unwrap()))
        .filter(memberships::user_id.eq(request.user_id.to_db_id().unwrap()))
        .execute(conn)
    {
        Ok(_) => {
            membership
                .map(|m| m.update_related_counts(conn))
                .transpose()?;
            Ok(())
        }
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
