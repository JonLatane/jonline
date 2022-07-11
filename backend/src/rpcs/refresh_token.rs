use crate::db_connection::*;
use crate::protos::*;
use tonic::{Request, Response, Status};

pub fn refresh_token(
    _request: Request<RefreshTokenRequest>,
    _conn: &PgPooledConnection,
) -> Result<Response<ExpirableToken>, Status> {
    Ok(Response::new(ExpirableToken {
        token: "example".to_owned(),
        expires_at: None,
    }))
}
