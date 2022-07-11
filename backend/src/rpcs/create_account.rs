use crate::db_connection::*;
use crate::protos::*;
use crate::schema::users::dsl::*;
use crate::rpcs::auth;
use bcrypt::{hash, DEFAULT_COST};
use diesel::*;
use tonic::{Code, Request, Response, Status};

pub fn create_account(
    conn: &PgPooledConnection,
    request: Request<CreateAccountRequest>,
) -> Result<Response<LoginResponse>, Status> {
    let req = request.into_inner();
    let hashed_password = hash(req.password, DEFAULT_COST).unwrap();

    let inserted_ids: Result<Vec<i32>, _> = insert_into(users)
        .values((
            username.eq(req.username.to_owned()),
            password_salted_hash.eq(hashed_password),
            email.eq(req.email.to_owned()),
            phone.eq(req.phone.to_owned()),
        ))
        .returning(id)
        .get_results(conn);

    let user: User = match inserted_ids {
        Err(_) => return Err(Status::new(Code::AlreadyExists, "username_already_exists")),
        Ok(ids) => User {
            id: bs58::encode(ids.first().unwrap().to_string()).into_string(),
            username: req.username,
            email: req.email,
            phone: req.phone,
        },
    };

    return Ok(Response::new(auth::generate_auth_and_refresh_token(user)));
}
