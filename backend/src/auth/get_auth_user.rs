use diesel::*;
use tonic::{Code, Request, Status};

use crate::db_connection::*;
use crate::models;
use crate::schema;
use crate::schema::user_access_tokens::dsl as user_access_tokens;
use crate::schema::user_refresh_tokens::dsl as user_refresh_tokens;
use crate::schema::users::dsl as users;

pub fn get_auth_user_id<T>(
    request: &Request<T>,
    conn: &mut PgPooledConnection,
) -> Result<Option<i64>, Status> {
    let access_token = match request.metadata().get("authorization") {
        Some(token) => token.to_str().unwrap().to_owned(),
        None => return Ok(None),
    };

    // delete(
    //     user_access_tokens::user_access_tokens
    //         .filter(user_access_tokens::token.eq(access_token.to_owned()))
    //         .filter(user_access_tokens::expires_at.lt(diesel::dsl::now)),
    // )
    // .execute(conn)
    // .unwrap_or(0);

    let user_id: Result<i64, _> = schema::user_access_tokens::table
        .inner_join(schema::user_refresh_tokens::table)
        .select(user_refresh_tokens::user_id)
        .filter(user_access_tokens::token.eq(access_token))
        .first::<i64>(conn);

    match user_id {
        Ok(user_id) => Ok(Some(user_id)),
        Err(_) => Err(Status::new(Code::Unauthenticated, "invalid_auth_token")),
    }
}

pub fn get_auth_user<T>(
    request: &Request<T>,
    conn: &mut PgPooledConnection,
) -> Result<Option<models::User>, Status> {
    let user_id = get_auth_user_id(request, conn);
    match user_id {
        Ok(Some(user_id)) => Ok(schema::users::table
            .filter(users::id.eq(user_id))
            .first::<models::User>(conn)
            .ok()),
        Ok(None) => Ok(None),
        Err(status) => Err(status),
    }
    // let user: models::User = match user_id {
    //     Err(status) => return Err(status),
    //     Ok(user_id) => schema::users::table
    //         .filter(users::id.eq(user_id))
    //         .first::<models::User>(conn)
    //         .unwrap(),
    // };
    // Ok(user)
}
