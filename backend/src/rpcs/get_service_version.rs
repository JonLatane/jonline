use tonic::Status;

use crate::protos::*;

const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn get_service_version() -> Result<GetServiceVersionResponse, Status> {
    println!("GetServiceVersion called, returning {}", VERSION);
    Ok(GetServiceVersionResponse {
        version: VERSION.to_owned(),
    })
}
