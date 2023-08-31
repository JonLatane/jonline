use bcrypt::{hash, DEFAULT_COST};
use diesel::*;
use tonic::{Code, Status};

use crate::auth;
use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{RefreshTokenResponse, CreateAccountRequest};
use crate::schema::users::dsl::*;

use super::{validations::*, get_server_configuration};

pub fn create_account(
    request: CreateAccountRequest,
    conn: &mut PgPooledConnection,
) -> Result<RefreshTokenResponse, Status> {
    validate_username(&request.username)?;
    validate_password(&request.password)?;
    match request.email.to_owned() {
        Some(e) => validate_email(&e.value)?,
        None => {}
    }
    match request.email.to_owned() {
        Some(e) => validate_phone(&e.value)?,
        None => {}
    }

    let hashed_password = hash(request.password, DEFAULT_COST).unwrap();

    let req_email: Option<serde_json::Value> = match request.email.map(|v| serde_json::to_value(v)) {
        None => None,
        Some(Err(_)) => None,
        Some(Ok(v)) => Some(v),
    };
    let req_phone: Option<serde_json::Value> = match request.phone.map(|v| serde_json::to_value(v)) {
        None => None,
        Some(Err(_)) => None,
        Some(Ok(v)) => Some(v),
    };
    let server_configuration = get_server_configuration(conn)?;
    let insert_result: Result<models::User, _> = insert_into(users)
        .values((
            username.eq(request.username.to_owned()),
            password_salted_hash.eq(hashed_password),
            email.eq(req_email),
            phone.eq(req_phone),
            permissions.eq(server_configuration.default_user_permissions.to_json_permissions()),
            moderation.eq(server_configuration.people_settings.as_ref().unwrap().default_moderation.to_string_moderation()),
            visibility.eq(server_configuration.people_settings.unwrap().default_visibility.to_string_visibility()),
        ))
        .get_result::<models::User>(conn);

    match insert_result {
        Err(e) => {
            print!("Username already exists {:?}", e);
            Err(Status::new(Code::AlreadyExists, "username_already_exists"))
        },
        Ok(user) => {
            let tokens = auth::generate_refresh_and_access_token(user.id, conn, request.expires_at);
            Ok(RefreshTokenResponse {
                refresh_token: tokens.refresh_token,
                access_token: tokens.access_token,
                user: Some(user.to_proto(&None, &None, None)),
            })
        }
    }
}
