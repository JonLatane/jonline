// use super::OperationType;
// use super::{validate_email, validate_phone, validate_username};
use tonic::{Code, Status};

// use crate::conversions::*;
use crate::protos::*;

pub fn validate_configuration(config: &ServerConfiguration) -> Result<(), Status> {

    if config.people_settings.as_ref().unwrap().default_visibility == Visibility::GlobalPublic as i32 
    && !config.default_user_permissions.contains(&(Permission::PublishUsersGlobally as i32)) {
        return Err(Status::new(
            Code::InvalidArgument, "global_public_users_require_PUBLISH_USERS_GLOBALLY_permission",
        ))
    }
    
    if config.default_client_domain.as_ref().map(|d| d.is_empty()).unwrap_or(false) {
        return Err(Status::new(
            Code::InvalidArgument, "default_client_domain_cannot_be_empty",
        ))
    }
    Ok(())
}
