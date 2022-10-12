
use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::db_connection::*;
use crate::protos::*;
use crate::schema::user_auth_tokens::dsl::*;


pub fn refresh_token(
    request: Request<RefreshTokenRequest>,
    conn: &mut PgPooledConnection,
) -> Result<Response<ExpirableToken>, Status> {
    println!("RefreshToken called.");
    let token_and_user_id: Result<(i32, i32), _> = user_auth_tokens
        .select((id, user_id))
        .filter(token.eq(request.into_inner().auth_token))
        .first::<(i32, i32)>(conn);

    match token_and_user_id {
        Ok((t, u)) => {
            println!(
                "Generating new refresh token for auth_token_id={}, user_id={}",
                t, u
            );
            Ok(Response::new(auth::generate_refresh_token(t, conn)))
        }
        Err(_) => {
            println!("Auth token not found.");
            Err(Status::new(Code::Unauthenticated, "not_authorized"))
        }
    }
}
