use bcrypt::verify;
use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::rpcs::validations::*;
use crate::schema::users::dsl::*;

pub fn login(
    request: Request<LoginRequest>,
    conn: &mut PgPooledConnection,
) -> Result<Response<RefreshTokenResponse>, Status> {
    let req = request.into_inner();
    validate_username(&req.username)?;
    validate_password(&req.password)?;

    let permission_denied = Status::new(Code::PermissionDenied, "invalid_username_or_password");
    let user_result = users
        .filter(username.eq(&req.username))
        .first::<models::User>(conn);
    let user: models::User = match user_result {
        Err(_) => return Err(permission_denied),
        Ok(user) => user,
    };

    let tokens = match verify(req.password, &user.password_salted_hash) {
        Err(_) => return Err(permission_denied),
        Ok(false) => return Err(permission_denied),
        Ok(true) => auth::generate_refresh_and_access_token(user.id, conn, req.expires_at),
    };

    println!("Logged in user {}, user_id={}", &req.username, user.id);

    Ok(Response::new(RefreshTokenResponse {
        refresh_token: tokens.refresh_token,
        access_token: tokens.access_token,
        user: Some(user.to_proto()),
    }))
}
