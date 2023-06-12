use tonic::Status;
use std::fs::read_to_string;

use crate::protos::*;

const VERSION: &str = env!("CARGO_PKG_VERSION");

lazy_static! {
    static ref SHA_HASH: Option<String> = match read_to_string("opt/continuous_delivery_hash") {
        Ok(hash) if hash.len() > 0 => Some(hash.trim().to_string()),
        _ => None
    };
}

pub fn get_service_version() -> Result<GetServiceVersionResponse, Status> {
    let version: String = match *SHA_HASH {
        Some(ref h) => format!("{}-{}", VERSION, h),
        None => VERSION.to_string(),
    };
    log::info!("GetServiceVersion called, returning {}", version);
    Ok(GetServiceVersionResponse {version: version })
}
