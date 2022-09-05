use tonic::{Code, Status};
use regex::Regex;

pub fn validate_all_word_chars(
    value: &str,
    entity_name: &str
) -> Result<(), Status> {
    let re = Regex::new(r"^[w]+$").unwrap();
    if re.is_match(value) {
        return Ok(());
    }
    Err(Status::new(
        Code::InvalidArgument,
        format!("{}_contains_non_word_chars", entity_name),
    ))
}

pub fn validate_reserved_values(
    value: &str,
    entity_name: &str,
    reserved_values: &[&str],
) -> Result<(), Status> {
    if reserved_values.contains(&value) {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("{}_may_not_be_{}", entity_name, value),
        ));
    }
    Ok(())
}
