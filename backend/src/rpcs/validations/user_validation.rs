use super::{validate_email, validate_phone, validate_username};
use tonic::{Code, Status};

use crate::conversions::*;
use crate::protos::*;

pub fn validate_user(user: &User) -> Result<(), Status> {
    validate_username(&user.username)?;
    match user.email.to_owned() {
        Some(e) => validate_email(&e.value)?,
        None => {}
    }
    match user.email.to_owned() {
        Some(e) => validate_phone(&e.value)?,
        None => {}
    }
    match user.avatar {
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
    match user.visibility.to_proto_visibility().unwrap() {
        Visibility::Unknown => return Err(Status::new(Code::NotFound, "invalid_visibility")),
        _ => (),
    };
    match user
        .default_follow_moderation
        .to_proto_moderation()
        .unwrap()
    {
        Moderation::Pending | Moderation::Unmoderated => (),
        _ => {
            return Err(Status::new(
                Code::NotFound,
                "invalid_default_follow_moderation",
            ))
        }
    };
    for permission in user.permissions.to_proto_permissions() {
        match permission {
            Permission::Unknown => {
                return Err(Status::new(
                    Code::NotFound,
                    format!("invalid_permission_{}", permission.as_str_name()),
                ))
            }
            _ => (),
        };
    }
    Ok(())
}
