// use super::OperationType;
// use super::{validate_email, validate_phone, validate_username};
use tonic::{Code, Status};

// use crate::conversions::*;
use crate::protos::*;

pub fn validate_configuration(config: &ServerConfiguration) -> Result<(), Status> {

    if config.people_settings.as_ref().unwrap().default_visibility == Visibility::GlobalPublic as i32 
    && !config.default_user_permissions.contains(&(Permission::PublishUsersGlobally as i32)) {
        return Err(Status::new(
            Code::NotFound, "global_public_users_require_PUBLISH_USERS_GLOBALLY_permission",
        ))
    }
    Ok(())
}
