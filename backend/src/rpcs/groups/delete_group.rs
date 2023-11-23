use diesel::*;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::groups;

use crate::rpcs::validations::*;

pub fn delete_group(
    request: Group,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    validate_group(&request)?;
    let (group, membership) = models::get_group_and_membership(
        request.id.to_db_id_or_err("id")?,
        Some(user.id),
        conn,
    )?;
    validate_group_admin(&Some(user), &group, &membership.as_ref())?;

    let group = groups::table
        .select(groups::all_columns)
        .filter(groups::id.eq(request.id.to_db_id_or_err("id")?))
        .first::<models::Group>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;

    match diesel::delete(groups::table)
        .filter(groups::id.eq(group.id))
        .execute(conn)
    {
        Ok(_) => Ok(()),
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
