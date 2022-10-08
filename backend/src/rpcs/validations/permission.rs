use tonic::{Code, Status};

use crate::{models, protos};
use crate::conversions::*;
pub fn validate_permission(
    user: &models::User,
    permission: protos::Permission
) -> Result<(), Status> {
    validate_any_permission(user, vec![permission, protos::Permission::Admin])
}

pub fn validate_any_permission(
    user: &models::User,
    permissions: Vec<protos::Permission>
) -> Result<(), Status> {
    let proto_permissions = user.permissions.to_proto_permissions();
    println!("User permissions: {:?}", proto_permissions);
    println!("Needed: {:?}", permissions);
    let passes = permissions.iter().any(|p| proto_permissions.contains(p));
    if !passes {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("permission_{}_required", permissions[0].as_str_name()),
        ));
    }
    Ok(())
}
