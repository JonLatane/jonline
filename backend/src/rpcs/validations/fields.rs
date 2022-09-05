use tonic::Status;
use super::string_length::validate_length;
use super::matching::*;
use super::matching::validate_all_word_chars;

pub fn validate_username(value: &str) -> Result<(), Status> {
  validate_length(&value, "username", 1, 47)?;
  validate_all_word_chars(&value, "username")?;
  validate_reserved_values(&value, "username", &["events", "posts", "e", "p"])
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
