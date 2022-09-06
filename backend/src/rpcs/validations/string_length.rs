use tonic::{Code, Status};

pub fn validate_length(
    value: &str,
    entity_name: &str,
    min_length: usize,
    max_length: usize,
) -> Result<(), Status> {
    if value.len() < min_length {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("{}_too_short_min_{}", entity_name, min_length),
        ));
    }
    if value.len() > max_length {
        return Err(Status::new(
            Code::InvalidArgument,
            format!("{}_too_long_max_{}", entity_name, max_length),
        ));
    }
    Ok(())
}
