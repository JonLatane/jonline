use tonic::{Request, Response, Status};

use crate::db_connection::*;
use crate::protos::*;

pub fn refresh_token(
    _request: Request<RefreshTokenRequest>,
    _conn: &PgPooledConnection,
) -> Result<Response<ExpirableToken>, Status> {
    println!("RefreshToken called.");
    Ok(Response::new(ExpirableToken {
        token: "example".to_owned(),
        expires_at: None,
    }))
}
