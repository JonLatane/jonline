use bcrypt::verify;
use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{AuthTokenResponse, LoginRequest};
use crate::schema::users::dsl::*;

use super::validate_length;

pub fn login(
    request: Request<LoginRequest>,
    conn: &PgPooledConnection,
) -> Result<Response<AuthTokenResponse>, Status> {
    let req = request.into_inner();
    validate_length(&req.password, "password", 8, 128)?;

    let permission_denied = Status::new(Code::PermissionDenied, "invalid_username_or_password");
    let user_result = users
        .filter(username.eq(req.username))
        .first::<models::User>(conn);
    let user: models::User = match user_result {
        Err(_) => return Err(permission_denied),
        Ok(user) => user,
    };

    let tokens = match verify(req.password, &user.password_salted_hash) {
        Err(_) => return Err(permission_denied),
        Ok(false) => return Err(permission_denied),
        Ok(true) => auth::generate_auth_and_refresh_token(user.id, conn),
    };

    Ok(Response::new(AuthTokenResponse {
        auth_token: tokens.auth_token,
        refresh_token: tokens.refresh_token,
        user: Some(auth::user_response(
            user.id,
            user.username,
            user.email,
            user.phone,
        )),
    }))
}
