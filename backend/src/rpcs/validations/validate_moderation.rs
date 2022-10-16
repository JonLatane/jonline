use tonic::{Code, Status};

use crate::models;

pub fn validate_group_moderation(membership: &models::Membership) -> Result<(), Status> {
  validate_moderation(&membership.group_moderation, "group_moderation")
}

pub fn validate_user_moderation(membership: &models::Membership) -> Result<(), Status> {
  validate_moderation(&membership.user_moderation, "user_moderation")
}

fn validate_moderation(value: &str, field_name: &str) -> Result<(), Status> {
    if !PASSING_MODERATIONS.iter().any(|&v| v == value) {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("{}_{}_invalid", field_name, value),
        ));
    }
    Ok(())
}

pub static PASSING_MODERATIONS: [&str; 2] = [
    "UNMODERATED", "APPROVED"
];
