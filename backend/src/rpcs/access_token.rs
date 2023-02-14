
use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::db_connection::*;
use crate::protos::*;
use crate::schema::user_refresh_tokens::dsl::*;


pub fn access_token(
    request: Request<AccessTokenRequest>,
    conn: &mut PgPooledConnection,
) -> Result<Response<AccessTokenResponse>, Status> {
    log::info!("AccessToken called.");
    let token_and_user_id: Result<(i32, i32), _> = user_refresh_tokens
        .select((id, user_id))
        .filter(token.eq(request.into_inner().refresh_token))
        .first::<(i32, i32)>(conn);

    match token_and_user_id {
        Ok((t, u)) => {
            log::info!(
                "Generating new access token for refresh_token_id={}, user_id={}",
                t, u
            );
            Ok(Response::new(AccessTokenResponse {
                access_token: Some(auth::generate_access_token(t, conn)),
                ..Default::default()
            }))
        }
        Err(_) => {
            log::warn!("Auth token not found.");
            Err(Status::new(Code::Unauthenticated, "not_authorized"))
        }
    }
}
