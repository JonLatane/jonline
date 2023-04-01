use tonic::{Code, Status};

use crate::marshaling::*;
use crate::models;
use crate::protos::Permission::*;
use crate::protos::*;

pub fn validate_group_admin(
    user: &models::User,
    membership: &Option<models::Membership>,
) -> Result<(), Status> {
    match validate_permission(user, Admin) {
        Ok(_) => Ok(()),
        Err(_) => match membership {
            Some(membership) => validate_group_permission(membership, user, Admin),
            None => Err(Status::new(
                Code::PermissionDenied,
                "admin_group_membership_required",
            )),
        },
    }
}

pub fn validate_group_user_moderator(
    user: &models::User,
    membership: &Option<models::Membership>,
) -> Result<(), Status> {
    match validate_group_admin(user, membership) {
        Ok(_) => Ok(()),
        Err(_) => match membership {
            Some(membership) => Ok(validate_group_permission(membership, user, ModerateUsers)?),
            None => Err(Status::new(
                Code::PermissionDenied,
                "moderator_group_membership_required",
            )),
        },
    }
}

pub fn validate_group_permission(
    membership: &models::Membership,
    user: &models::User,
    permission: Permission,
) -> Result<(), Status> {
    validate_any_group_permission(membership, user, vec![permission, Admin])
}

pub fn validate_any_group_permission(
    membership: &models::Membership,
    user: &models::User,
    permissions: Vec<Permission>,
) -> Result<(), Status> {
    let proto_permissions = membership.permissions.to_proto_permissions();
    // log::info!("User permissions: {:?}", proto_permissions);
    // log::info!("Needed: {:?}", permissions);
    let passes = permissions.iter().any(|p| proto_permissions.contains(p));
    if !passes {
        match validate_any_permission(user, vec![Admin, ModerateGroups]) {
            Ok(_) => (),
            Err(_) => 
                return Err(Status::new(
                    Code::InvalidArgument,
                    format!("group_permission_{}_required", permissions[0].as_str_name()),
                ))
            
        }
    }
    Ok(())
}

pub fn validate_permission(user: &models::User, permission: Permission) -> Result<(), Status> {
    validate_any_permission(user, vec![permission, Admin])
}

pub fn validate_any_permission(
    user: &models::User,
    permissions: Vec<Permission>,
) -> Result<(), Status> {
    let proto_permissions = user.permissions.to_proto_permissions();
    // log::info!("User permissions: {:?}", proto_permissions);
    // log::info!("Needed: {:?}", permissions);
    let passes = permissions.iter().any(|p| proto_permissions.contains(p));
    if !passes {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("permission_{}_required", permissions[0].as_str_name()),
        ));
    }
    Ok(())
}
