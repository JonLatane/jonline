use crate::db_connection::*;
use crate::protos::*;
use crate::schema::users::dsl::*;
use diesel::*;
use tonic::{Code, Request, Response, Status};
use bcrypt::{DEFAULT_COST, hash};


pub fn login(
    conn: &PgPooledConnection,
    request: Request<LoginRequestRequest>,
) -> Result<Response<LoginResponse>, Status> {
    // let req = request.into_inner();
    // let hashed_password = hash(req.password, DEFAULT_COST).unwrap();

    // let inserted_ids: Result<Vec<i32>, _> = insert_into(users)
    //     .values((
    //         username.eq(req.username.to_owned()),
    //         password_salted_hash.eq(hashed_password),
    //         email.eq(req.email.to_owned()),
    //         phone.eq(req.phone.to_owned()),
    //     ))
    //     .returning(id)
    //     .get_results(conn);

    // match inserted_ids {
        /*Ok(ids) => */Ok(Response::new(LoginResponse {
            auth_token: Some(ExpirableToken {
                token: "".to_owned(),
                expires_at: None,
            }),
            refresh_token: Some(ExpirableToken {
                token: "".to_owned(),
                expires_at: None,
            }),
            user: User {
                id: "".to_owned(),
                username: req.username,
                email: None,
                phone: None,
            },
        }))//,
    //     Err(_) => Err(Status::new(Code::AlreadyExists, "User already exists")),
    // }
}
