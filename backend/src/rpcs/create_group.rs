use diesel::result::DatabaseErrorKind::UniqueViolation;
use diesel::result::Error::DatabaseError;
use diesel::*;
use tonic::{Code, Status};

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
    conn: &mut PgPooledConnection,
) -> Result<Group, Status> {
    validate_permission(&user, Permission::CreateGroups)?;
    validate_group(&request)?;

    let visibility = match request.visibility.to_proto_visibility() {
        Some(Visibility::Unknown) => Visibility::ServerPublic,
        Some(v) => v,
        _ => Visibility::ServerPublic,
    }
    .to_string_visibility();
    let default_membership_moderation =
        match request.default_membership_moderation.to_proto_moderation() {
            Some(Moderation::Pending) => Moderation::Pending,
            _ => Moderation::Unmoderated,
        }
        .to_string_moderation();
    let default_post_moderation = match request.default_post_moderation.to_proto_moderation() {
        Some(Moderation::Pending) => Moderation::Pending,
        _ => Moderation::Unmoderated,
    }
    .to_string_moderation();
    let default_event_moderation = match request.default_event_moderation.to_proto_moderation() {
        Some(Moderation::Pending) => Moderation::Pending,
        _ => Moderation::Unmoderated,
    }
    .to_string_moderation();
    let mut default_membership_permissions =
        request.default_membership_permissions.to_json_permissions();
    if request.default_membership_permissions.is_empty() {
        default_membership_permissions =
            vec![Permission::ViewPosts, Permission::ViewEvents].to_json_permissions();
    }
    let mut membership: Option<models::Membership> = None;
    let group: Result<models::Group, diesel::result::Error> = conn
        .transaction::<models::Group, diesel::result::Error, _>(|conn| {
            let group = insert_into(groups::table)
                .values(&models::NewGroup {
                    name: request.name,
                    description: request.description,
                    avatar: request.avatar,
                    visibility: visibility,
                    default_membership_permissions: default_membership_permissions,
                    default_membership_moderation: default_membership_moderation,
                    default_post_moderation: default_post_moderation,
                    default_event_moderation: default_event_moderation,
                    member_count: 1,
                })
                .get_result::<models::Group>(conn)?;

            let group_moderation =
                match request.default_membership_moderation.to_proto_moderation() {
                    Some(Moderation::Unmoderated) => Moderation::Unmoderated,
                    _ => Moderation::Approved,
                }
                .to_string_moderation();
            membership = Some(
                insert_into(memberships::table)
                    .values(&models::NewMembership {
                        user_id: user.id,
                        group_id: group.id,
                        permissions: vec![Permission::Admin].to_json_permissions(),
                        group_moderation: group_moderation,
                        user_moderation: Moderation::Approved.to_string_moderation(),
                    })
                    .get_result::<models::Membership>(conn)?,
            );
            Ok(group)
        });

    match group {
        Ok(group) => {
            println!("Group created! Result: {:?}", group);
            Ok(group.to_proto_with(membership.map(|m| m.to_proto())))
        }
        Err(DatabaseError(UniqueViolation, _)) => {
            Err(Status::new(Code::NotFound, "duplicate_group_name"))
        }
        Err(e) => {
            println!("Error creating group! {:?}", e);
            Err(Status::new(Code::Internal, "internal_error"))
        }
    }
}
