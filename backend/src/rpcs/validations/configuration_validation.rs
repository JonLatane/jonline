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
    
    let external_edn_config = config.external_cdn_config.to_owned();
    let backend_host = external_edn_config.to_owned().map(|c| c.backend_host);
    let frontend_host = external_edn_config.map(|c| c.frontend_host);
    match (backend_host, frontend_host) {
        (None, None) => (),
        (Some(be), Some(fe)) if !be.is_empty() && !fe.is_empty() => (),
        _ => return Err(Status::new(
            Code::InvalidArgument, "default_client_domain_cannot_be_empty",
        ))
    }
    Ok(())
}
