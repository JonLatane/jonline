// use super::OperationType;
// use super::{validate_email, validate_phone, validate_username};
use regex::Regex;
use tonic::{Code, Status};

// use crate::conversions::*;
use crate::protos::*;

pub fn validate_configuration(config: &ServerConfiguration) -> Result<(), Status> {
    if let Some(custom_tabs) = config.custom_tabs.as_ref() {
        let path_re = Regex::new(r"^[a-z_]+$").unwrap();
        for tab in &custom_tabs.tabs {
            // A profile tab's `path` *is* the username it links to (see the proto's own doc on
            // `is_profile`), so it's validated as a username instead (`validate_username`'s own
            // `[\w.-]+` word-char rule) -- not `[a-z_]+`, which most real usernames (mixed case,
            // digits) would fail.
            let is_profile_tab = matches!(
                tab.custom_tab.as_ref().and_then(|ct| ct.target.as_ref()),
                Some(custom_navigation_tab::Target::IsProfile(_))
            );
            if is_profile_tab {
                super::validate_username(&tab.path)?;
            } else if !path_re.is_match(&tab.path) {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "custom_tab_path_must_match_[a-z_]",
                ));
            }
        }
    }

    if config.people_settings.as_ref().unwrap().default_visibility
        == Visibility::GlobalPublic as i32
        && !config
            .default_user_permissions
            .contains(&(Permission::PublishUsersGlobally as i32))
    {
        return Err(Status::new(
            Code::InvalidArgument,
            "global_public_users_require_PUBLISH_USERS_GLOBALLY_permission",
        ));
    }

    let external_edn_config = config.external_cdn_config.to_owned();
    let backend_host = external_edn_config.to_owned().map(|c| c.backend_host);
    let frontend_host = external_edn_config.map(|c| c.frontend_host);
    match (backend_host, frontend_host) {
        (None, None) => (),
        (Some(be), Some(fe)) if !be.is_empty() && !fe.is_empty() => (),
        _ => {
            return Err(Status::new(
                Code::InvalidArgument,
                "default_client_domain_cannot_be_empty",
            ))
        }
    }
    Ok(())
}
