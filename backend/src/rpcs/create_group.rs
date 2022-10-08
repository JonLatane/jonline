use diesel::*;
use tonic::{Code, Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::groups;
use crate::schema::memberships;

use super::validations::*;

pub fn create_group(
    request: Group,
    user: models::User,
    conn: &PgPooledConnection,
) -> Result<Response<Group>, Status> {
    validate_permission(&user, Permission::CreateGroups)?;
    validate_length(&request.name, "name", 1, 128)?;
    validate_max_length(request.description.to_owned(), "description", 10000)?;

    let visibility = match request.visibility.to_proto_visibility() {
        Some(Visibility::Unknown) => Visibility::ServerPublic,
        Some(v) => v,
        _ => Visibility::ServerPublic
    }.to_string_visibility();
    let default_membership_moderation =
        match request.default_membership_moderation.to_proto_moderation() {
            Some(Moderation::Pending) => Moderation::Pending,
            Some(Moderation::Unmoderated) => Moderation::Unmoderated,
            _ => Moderation::Unmoderated,
        }
        .to_string_moderation();
    let default_membership_permissions =
        request.default_membership_permissions.to_json_permissions();
    let group: Result<models::Group, _> = conn
        .transaction::<models::Group, diesel::result::Error, _>(|| {
            let group = insert_into(groups::table)
                .values(&models::NewGroup {
                    name: request.name,
                    description: request.description,
                    avatar: request.avatar,
                    visibility: visibility,
                    default_membership_permissions: default_membership_permissions,
                    default_membership_moderation: default_membership_moderation,
                })
                .get_result::<models::Group>(conn)?;

            let group_moderation =
                match request.default_membership_moderation.to_proto_moderation() {
                    Some(Moderation::Unmoderated) => Moderation::Unmoderated,
                    _ => Moderation::Approved,
                }
                .to_string_moderation();
            let _membership = insert_into(memberships::table)
                .values(&models::NewMembership {
                    user_id: user.id,
                    group_id: group.id,
                    permissions: vec![Permission::Admin].to_json_permissions(),
                    group_moderation: group_moderation,
                    user_moderation: Moderation::Approved.to_string_moderation(),
                })
                .get_result::<models::Membership>(conn)?;
            Ok(group)
        });

    match group {
        Ok(group) => {
            println!("Group created! Result: {:?}", group);
            Ok(Response::new(group.to_proto(1)))
        }
        Err(e) => {
            println!("Error creating group! {:?}", e);
            Err(Status::new(Code::Internal, "internal_error"))
        }
    }
}
