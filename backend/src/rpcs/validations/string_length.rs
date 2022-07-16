use tonic::{Code, Status};

pub fn validate_username(value: &str) -> Result<(), Status> {
  validate_length(&value, "username", 1, 47)
}
pub fn validate_password(value: &str) -> Result<(), Status> {
  validate_length(&value, "password", 8, 128)
}
pub fn validate_email(value: &Option<String>) -> Result<(), Status> {
  match value {
    Some(value) => validate_length(&value, "email", 1, 255),
    None => Ok(()),
  }
}
pub fn validate_phone(value: &Option<String>) -> Result<(), Status> {
  match value {
    Some(value) => validate_length(&value, "phone", 1, 128),
    None => Ok(()),
  }
}

pub fn validate_length(
    value: &str,
    entity_name: &str,
    min_length: usize,
    max_length: usize,
) -> Result<(), Status> {
    if value.len() < min_length {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("{}_too_short_min{}", entity_name, min_length),
        ));
    }
    if value.len() > max_length {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("{}_too_long_max{}", entity_name, max_length),
        ));
    }
    Ok(())
}
