use bcrypt::{hash, DEFAULT_COST};
use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::conversions::ToProtoUser;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{AuthTokenResponse, CreateAccountRequest};
use crate::schema::users::dsl::*;

use super::validations::*;

pub fn create_account(
    request: Request<CreateAccountRequest>,
    conn: &PgPooledConnection,
) -> Result<Response<AuthTokenResponse>, Status> {
    let req = request.into_inner();
    validate_username(&req.username)?;
    validate_password(&req.password)?;
    validate_email(&req.email)?;
    validate_phone(&req.phone)?;

    let hashed_password = hash(req.password, DEFAULT_COST).unwrap();

    let insert_result: Result<models::User, _> = insert_into(users)
        .values((
            username.eq(req.username.to_owned()),
            password_salted_hash.eq(hashed_password),
            email.eq(&req.email.to_owned()),
            phone.eq(&req.phone.to_owned()),
        ))
        .get_result::<models::User>(conn);

    match insert_result {
        Err(_) => Err(Status::new(Code::AlreadyExists, "username_already_exists")),
        Ok(user) => {
            let tokens = auth::generate_auth_and_refresh_token(user.id, conn, req.expires_at);
             Ok(Response::new(AuthTokenResponse {
                auth_token: tokens.auth_token,
                refresh_token: tokens.refresh_token,
                user: Some(user.to_proto()),
            }))
        }
    }
}
