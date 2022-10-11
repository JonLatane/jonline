use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{groups, memberships};

pub fn create_membership(
    request: Membership,
    user: models::User,
    conn: &PgPooledConnection,
) -> Result<Membership, Status> {
    validate_membership(&request)?;
    let group = groups::table
        .select(groups::all_columns)
        .filter(groups::id.eq(request.group_id.to_db_id_or_err("group_id")?))
        .first::<models::Group>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;

    // Is the current user already in the group and an admin?
    let user_membership = match memberships::table
        .select(memberships::all_columns)
        .filter(memberships::user_id.eq(user.id))
        .filter(memberships::group_id.eq(request.group_id.to_db_id_or_err("group_id")?))
        .first::<models::Membership>(conn)
    {
        Ok(membership) => Some(membership),
        Err(diesel::NotFound) => None,
        Err(_) => return Err(Status::new(Code::Internal, "data_error")),
    };

    let result = if request.user_id.to_db_id_or_err("user_id")? == user.id {
        match user_membership {
            Some(_) => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "membership_already_exists",
                ));
            }
            None => create_membership_for_self(request, group, user, conn),
        }
    } else {
        match user_membership {
            None => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "membership_required_to_invite",
                ))
            }
            Some(membership) => create_membership_for_other(request, group, user, membership, conn),
        }
    };
    result.map(|membership| membership.to_proto())
}

fn create_membership_for_self(
    request: Membership,
    group: models::Group,
    user: models::User,
    conn: &PgPooledConnection,
) -> Result<models::Membership, Status> {
    let membership: Result<models::Membership, diesel::result::Error> = conn
        .transaction::<models::Membership, diesel::result::Error, _>(|| {
            let membership = insert_into(memberships::table)
                .values(&models::NewMembership {
                    user_id: user.id,
                    group_id: request.group_id.to_db_id().unwrap(),
                    permissions: request.permissions.to_json_permissions(),
                    group_moderation: group.default_membership_moderation,
                    user_moderation: request.user_moderation.to_string_moderation(),
                })
                .get_result::<models::Membership>(conn)?;
            Ok(membership)
        });
    membership.map_err(|e| {
        println!("Error creating membership! {:?}", e);
        Status::new(Code::Internal, "data_error")
    })
}

fn create_membership_for_other(
    request: Membership,
    group: models::Group,
    _user: models::User,
    user_membership: models::Membership,
    conn: &PgPooledConnection,
) -> Result<models::Membership, Status> {
    let group_moderation = match validate_any_group_permission(
        &user_membership,
        vec![Permission::Admin, Permission::ModerateUsers],
    ) {
        Ok(_) => Moderation::Approved.to_string_moderation(),
        Err(_) => group.default_membership_moderation,
    };

    let membership: Result<models::Membership, diesel::result::Error> = conn
        .transaction::<models::Membership, diesel::result::Error, _>(|| {
            let membership = insert_into(memberships::table)
                .values(&models::NewMembership {
                    user_id: request.user_id.to_db_id().unwrap(),
                    group_id: request.group_id.to_db_id().unwrap(),
                    permissions: request.permissions.to_json_permissions(),
                    group_moderation: group_moderation,
                    user_moderation: Moderation::Pending.to_string_moderation(),
                })
                .get_result::<models::Membership>(conn)?;
            Ok(membership)
        });
    membership.map_err(|e| {
        println!("Error creating membership! {:?}", e);
        Status::new(Code::Internal, "data_error")
    })
}
