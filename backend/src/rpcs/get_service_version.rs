use crate::protos::*;
use tonic::{Response, Status};

const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn get_service_version() -> Result<Response<GetServiceVersionResponse>, Status> {
    let response = GetServiceVersionResponse {
        version: VERSION.to_owned(),
    };
    Ok(Response::new(response))
}
