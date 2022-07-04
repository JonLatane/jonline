use tonic::{Request, Response, Status};
use crate::db_connection::*;
use crate::protos::*;

const VERSION: &str = env!("CARGO_PKG_VERSION");

pub fn get_service_version(
  _pool: &PgPool,
  _request: Request<()>,
) -> Result<Response<GetServiceVersionResponse>, Status> {
  let response = GetServiceVersionResponse {
      version: VERSION.to_owned()
  };
  Ok(Response::new(response))
}
