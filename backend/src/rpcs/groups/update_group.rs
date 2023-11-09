use std::time::SystemTime;

use diesel::result::DatabaseErrorKind::UniqueViolation;
use diesel::result::Error::DatabaseError;
use diesel::*;

use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::get_media_reference;
use crate::protos::*;
use crate::schema::groups;
use crate::schema::memberships;

use crate::rpcs::validations::*;

pub fn update_group(
    request: Group,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Group, Status> {
    validate_group(&request)?;

    match memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(user.id))
        .filter(memberships::group_id.eq(request.id.to_db_id_or_err("id")?))
        .first::<models::Membership>(conn)
    {
        Ok(membership) => {
            validate_group_admin(&user, &Some(membership))?;
        }
        Err(diesel::NotFound) => return Err(Status::new(Code::NotFound, "not_a_member")),
        Err(_) => return Err(Status::new(Code::Internal, "data_error")),
    };

    let mut group = groups::table
        .select(groups::all_columns)
        .filter(groups::id.eq(request.id.to_db_id_or_err("id")?))
        .first::<models::Group>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;

    let avatar = match &request.avatar.map(|a| a.id) {
        Some(id) => get_media_reference(id.to_db_id_or_err("avatar")?, conn).ok(),
        None => None,
    };

    group.name = request.name;
    group.description = request.description;
    group.avatar_media_id = avatar.map(|m| m.id);

    group.visibility = request.visibility.to_string_visibility();
    group.default_membership_permissions =
        request.default_membership_permissions.to_json_permissions();
    group.default_membership_moderation =
        request.default_membership_moderation.to_string_moderation();

    group.updated_at = SystemTime::now().into();

    match diesel::update(groups::table)
        .filter(groups::id.eq(request.id.to_db_id().unwrap()))
        .set(&group)
        .execute(conn)
    {
        Ok(_) => Ok(group.to_proto(conn, &Some(&user))),
        Err(DatabaseError(UniqueViolation, _)) => {
            Err(Status::new(Code::NotFound, "duplicate_group_name"))
        }
        Err(e) => {
            log::error!("Error updating group! {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    }
}
