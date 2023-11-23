use tonic::{Code, Status};

use crate::logic::Moderated;
use crate::marshaling::*;
use crate::models;
use crate::protos::Permission::*;
use crate::protos::*;

pub fn validate_group_admin(
    user: &Option<&models::User>,
    group: &models::Group,
    membership: &Option<&models::Membership>,
) -> Result<(), Status> {
    match validate_permission(user, Admin) {
        Ok(_) => Ok(()),
        Err(_) => Ok(validate_group_permission(group, membership, user, Admin)?)
        // match membership {
        //     Some(membership) => validate_group_permission(group, membership, user, Admin),
        //     None => Err(Status::new(
        //         Code::PermissionDenied,
        //         "admin_group_membership_required",
        //     )),
        // },
    }
}

pub fn validate_group_user_moderator(
    user: &Option<&models::User>,
    group: &models::Group,
    membership: &Option<&models::Membership>,
) -> Result<(), Status> {
    match validate_group_admin(user, group, membership) {
        Ok(_) => Ok(()),
        Err(_) => Ok(validate_group_permission(
            group,
            membership,
            user,
            ModerateUsers,
        )?),
    }
}

pub fn validate_group_permission(
    group: &models::Group,
    membership: &Option<&models::Membership>,
    user: &Option<&models::User>,
    permission: Permission,
) -> Result<(), Status> {
    validate_any_group_permission(group, membership, user, vec![permission, Admin])
}

pub fn validate_any_group_permission(
    group: &models::Group,
    membership: &Option<&models::Membership>,
    user: &Option<&models::User>,
    permissions: Vec<Permission>,
) -> Result<(), Status> {
    let proto_permissions = match membership {
        Some(m) if (*m).passes() => m.permissions.to_proto_permissions(),
        _ => group.non_member_permissions.to_proto_permissions(),
    } ;
    // membership
    //     .map(|m| m.permissions)
    //     .unwrap_or(group.non_member_permissions)
    //     .to_proto_permissions();

    let passes = permissions.iter().any(|p| proto_permissions.contains(p));
    if !passes {
        match validate_any_permission(user, vec![Admin, ModerateGroups]) {
            Ok(_) => (),
            Err(_) => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    format!("group_permission_{}_required", permissions[0].as_str_name()),
                ))
            }
        }
    }
    Ok(())
}

pub fn validate_permission(
    user: &Option<&models::User>,
    permission: Permission,
) -> Result<(), Status> {
    validate_any_permission(user, vec![permission, Admin])
}

pub fn validate_any_permission(
    user: &Option<&models::User>,
    permissions: Vec<Permission>,
) -> Result<(), Status> {
    let proto_permissions = user
        .map(|u| u.permissions.to_proto_permissions())
        .unwrap_or(vec![]);
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
