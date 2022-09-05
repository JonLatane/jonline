use tonic::{Response, Status};

use crate::protos::*;

const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn get_service_version() -> Result<Response<GetServiceVersionResponse>, Status> {
    println!("GetServiceVersion called, returning {}", VERSION);
    let response = GetServiceVersionResponse {
        version: VERSION.to_owned(),
    };
    Ok(Response::new(response))
}
