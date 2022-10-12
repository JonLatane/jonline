use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::memberships;

pub fn update_membership(
    request: Membership,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Membership, Status> {
    validate_membership(&request, OperationType::Create)?;
    // let group = groups::table
    //     .select(groups::all_columns)
    //     .filter(groups::id.eq(request.group_id.to_db_id_or_err("group_id")?))
    //     .first::<models::Group>(conn)
    //     .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;

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
    let mut admin = false;
    let mut moderator = false;
    if !self_update {
        match user_membership {
            None => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "membership_and_moderator_status_required",
                ))
            }
            Some(membership) => {
                validate_group_permission(&membership, Permission::ModerateUsers)?;
            }
        }
    }
    match validate_permission(&current_user, Permission::Admin) {
        Ok(_) => admin = true,
        Err(_) => {}
    };
    match validate_permission(&current_user, Permission::ModerateUsers) {
        Ok(_) => moderator = true,
        Err(_) => {}
    };
    let mut existing_membership = memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(request.user_id.to_db_id().unwrap()))
        .filter(memberships::group_id.eq(request.group_id.to_db_id().unwrap()))
        .first::<models::Membership>(conn)
        .map_err(|_| Status::new(Code::NotFound, "membership_not_found"))?;

    if self_update {
        existing_membership.user_moderation = request.user_moderation.to_string_moderation();
    }
    if admin || moderator {
        existing_membership.group_moderation = request.group_moderation.to_string_moderation();
    }
    if admin {
        existing_membership.permissions = request.permissions.to_json_permissions();
    }
    existing_membership.updated_at = SystemTime::now().into();

    match diesel::update(memberships::table)
        .filter(memberships::user_id.eq(request.user_id.to_db_id().unwrap()))
        .filter(memberships::group_id.eq(request.group_id.to_db_id().unwrap()))
        .set(&existing_membership)
        .execute(conn)
    {
        Ok(_) => {
            existing_membership.update_related_counts(conn)?;
            Ok(existing_membership.to_proto())
        }
        ,
        Err(e) => {
            println!("Error updating membership: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating_membership"))
        }
    }
}
