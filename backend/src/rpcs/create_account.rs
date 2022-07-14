use bcrypt::{hash, DEFAULT_COST};
use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::db_connection::PgPooledConnection;
use crate::protos::{AuthTokenResponse, CreateAccountRequest};
use crate::schema::users::dsl::*;

use super::validate_length;

pub fn create_account(
    request: Request<CreateAccountRequest>,
    conn: &PgPooledConnection,
) -> Result<Response<AuthTokenResponse>, Status> {
    let req = request.into_inner();
    validate_length(&req.username, "username", 1, 47)?;
    validate_length(&req.password, "password", 8, 128)?;

    let hashed_password = hash(req.password, DEFAULT_COST).unwrap();

    let insert_result: Result<i32, _> = insert_into(users)
        .values((
            username.eq(req.username.to_owned()),
            password_salted_hash.eq(hashed_password),
            email.eq(req.email.to_owned()),
            phone.eq(req.phone.to_owned()),
        ))
        .returning(id)
        .get_result(conn);

    let user_id: i32 = match insert_result {
        Err(_) => return Err(Status::new(Code::AlreadyExists, "username_already_exists")),
        Ok(user_id) => user_id,
    };

    let tokens = auth::generate_auth_and_refresh_token(user_id, conn);
    return Ok(Response::new(AuthTokenResponse {
        auth_token: tokens.auth_token,
        refresh_token: tokens.refresh_token,
        user: Some(auth::user_response(
            user_id,
            req.username,
            req.email,
            req.phone,
        )),
    }));
}
