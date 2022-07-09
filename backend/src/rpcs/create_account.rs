use crate::db_connection::*;
use crate::protos::*;
use crate::schema::users::dsl::*;
use diesel::*;
use tonic::{Code, Request, Response, Status};
use bcrypt::{DEFAULT_COST, hash};


pub fn create_account(
    conn: &PgPooledConnection,
    request: Request<CreateAccountRequest>,
) -> Result<Response<User>, Status> {
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

    match inserted_ids {
        Ok(ids) => Ok(Response::new(User {
            id: bs58::encode(ids.first().unwrap().to_string()).into_string(),
            username: req.username,
            email: req.email,
            phone: req.phone
        })),
        Err(_) => Err(Status::new(Code::AlreadyExists, "User already exists")),
    }
}
