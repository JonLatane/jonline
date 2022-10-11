use super::OperationType;
use super::string_length_validation::*;
use tonic::{Code, Status};

use crate::conversions::*;
use crate::protos::*;

pub fn validate_group(group: &Group) -> Result<(), Status> {
    validate_length(&group.name, "name", 1, 128)?;
    validate_max_length(group.description.to_owned(), "description", 10000)?;
    match group.avatar {
        None => {}
        Some(ref avatar) => {
            if avatar.len() > 1000000 {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "avatar_too_large_max_1000000",
                ));
            }
        }
    };
    match group.visibility.to_proto_visibility().unwrap() {
        Visibility::Unknown => return Err(Status::new(Code::NotFound, "invalid_visibility")),
        _ => (),
    };
    for permission in group.default_membership_permissions.to_proto_permissions() {
        match permission {
            Permission::ViewPosts
            | Permission::CreatePosts
            | Permission::ModeratePosts
            | Permission::ViewEvents
            | Permission::CreateEvents
            | Permission::ModerateEvents
            | Permission::ModerateUsers
            | Permission::Admin => (),
            permission => {
                return Err(Status::new(
                    Code::NotFound,
                    format!("invalid_permission_{}", permission.as_str_name()),
                ))
            }
        };
    }
    match group
        .default_membership_moderation
        .to_proto_moderation()
        .unwrap()
    {
        Moderation::Unmoderated | Moderation::Pending => {}
        _ => {
            return Err(Status::new(
                Code::Internal,
                "invalid_default_membership_moderation",
            ))
        }
    };
    Ok(())
}

pub fn validate_membership(membership: &Membership, operation_type: OperationType) -> Result<(), Status> {
    membership.user_id.to_db_id_or_err("user_id")?;
    membership.group_id.to_db_id_or_err("group_id")?;
    match operation_type { OperationType::Delete | OperationType::Create => return Ok(()), _ => () };
    for permission in membership.permissions.to_proto_permissions() {
        match permission {
            Permission::ViewPosts
            | Permission::CreatePosts
            | Permission::ModeratePosts
            | Permission::ViewEvents
            | Permission::CreateEvents
            | Permission::ModerateEvents
            | Permission::ModerateUsers
            | Permission::Admin => (),
            permission => {
                return Err(Status::new(
                    Code::NotFound,
                    format!("invalid_permission_{}", permission.as_str_name()),
                ))
            }
        };
    }
    match membership.group_moderation.to_proto_moderation().unwrap() {
        Moderation::Unmoderated | Moderation::Pending => {}
        _ => return Err(Status::new(Code::Internal, "invalid_group_moderation")),
    };
    match membership.user_moderation.to_proto_moderation().unwrap() {
        Moderation::Unmoderated | Moderation::Pending => {}
        _ => return Err(Status::new(Code::Internal, "invalid_user_moderation")),
    };
    Ok(())
}
