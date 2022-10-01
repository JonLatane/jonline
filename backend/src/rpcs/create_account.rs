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
    match req.email.to_owned() {
        Some(e) => validate_email(&e.value)?,
        None => {}
    }
    match req.email.to_owned() {
        Some(e) => validate_phone(&e.value)?,
        None => {}
    }

    let hashed_password = hash(req.password, DEFAULT_COST).unwrap();

    let req_email: Option<serde_json::Value> = match req.email.map(|v| serde_json::to_value(v)) {
        None => None,
        Some(Err(_)) => None,
        Some(Ok(v)) => Some(v),
    };
    let req_phone: Option<serde_json::Value> = match req.phone.map(|v| serde_json::to_value(v)) {
        None => None,
        Some(Err(_)) => None,
        Some(Ok(v)) => Some(v),
    };
    let insert_result: Result<models::User, _> = insert_into(users)
        .values((
            username.eq(req.username.to_owned()),
            password_salted_hash.eq(hashed_password),
            email.eq(req_email),
            phone.eq(req_phone),
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
