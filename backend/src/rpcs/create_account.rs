// extern crate diesel;

// use self::diesel_demo::*;
// use self::models::*;
// use self::diesel::prelude::*;
// #[macro_use]
// extern crate diesel;
use crate::db_connection::*;
use crate::protos::*;
use crate::schema::users::dsl::*;
use diesel::*;
use tonic::{Code, Request, Response, Status};
// use passwors::*;

pub fn create_account(
    conn: &PgPooledConnection,
    request: Request<CreateAccountRequest>,
) -> Result<Response<UpdateResponse>, Status> {
    let req = request.into_inner();

    // let pw      = ClearTextPassword::from_string(req.password).unwrap();
    // let salt    = HashSalt::new().unwrap();  // You should grab this from your database.
    // let a2hash  = Argon2PasswordHasher::default();
    // let hashed_password = pw.hash(&a2hash, &salt);

// assert_eq!(pw_hash, stored_hash, "Login failed!");

    let result = insert_into(users)
        .values((
            username.eq(req.username),
            password_salted_hash.eq(req.password),
            email.eq(req.email),
            phone.eq(req.phone),
        ))
        .execute(conn);

    match result {
        Ok(_) => Ok(Response::new(UpdateResponse {
            result: update_response::Result::Ok as i32,
            messages: [].to_vec(),
        })),
        Err(_) => Err(Status::new(Code::AlreadyExists, "User already exists")),
    }
}
