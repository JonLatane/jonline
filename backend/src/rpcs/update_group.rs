use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::groups;
use crate::schema::memberships;

use super::validations::*;

pub fn update_group(
    request: Group,
    user: models::User,
    conn: &PgPooledConnection,
) -> Result<Group, Status> {
    validate_group(&request)?;
    match memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(user.id))
        .filter(memberships::group_id.eq(request.id.to_db_id_or_err("id")?))
        .first::<models::Membership>(conn)
    {
        Ok(membership) => {
            validate_group_or_general_admin(&user, &Some(membership))?;
        }
        Err(diesel::NotFound) => return Err(Status::new(Code::NotFound, "not_a_member")),
        Err(_) => return Err(Status::new(Code::Internal, "data_error")),
    };

    let mut group = groups::table
        .select(groups::all_columns)
        .filter(groups::id.eq(request.id.to_db_id_or_err("id")?))
        .first::<models::Group>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;

    group.name = request.name;
    group.description = request.description;
    group.avatar = request.avatar;
    group.visibility = request.visibility.to_string_visibility();
    group.default_membership_permissions = request.default_membership_permissions.to_json_permissions();
    group.default_membership_moderation = request.default_membership_moderation.to_string_moderation();
    group.updated_at = SystemTime::now().into();

    match diesel::update(groups::table).set(&group).execute(conn) {
        Ok(_) => Ok(group.to_proto(&conn, &Some(user))),
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
