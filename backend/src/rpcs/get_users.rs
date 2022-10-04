use diesel::*;
use tonic::{Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema;

// use super::validations::*;

pub fn get_users(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<Response<GetUsersResponse>, Status> {
    println!("GetUsers called");
    let response = match request.to_owned().username {
        Some(_) => {
            get_by_username(request.to_owned(), user, conn)
        }
        None => get_all_users(request.to_owned(), user, conn),
    };
    println!("GetUsers::request: {:?}, response: {:?}", request, response);
    Ok(Response::new(response))
}


fn get_all_users(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetUsersResponse {
    let visibility = match user {
        Some(_) => Visibility::ServerPublic,
        None => Visibility::GlobalPublic,
    };
    let users = schema::users::table
            .select(schema::users::all_columns)
            .filter(schema::users::visibility.eq(visibility.as_str_name()))
            .order(schema::users::created_at.desc())
            .limit(100)
            .offset((request.page.unwrap_or(0) * 100).into())
            .load::<models::User>(conn)
            .unwrap()
            .iter()
            .map(|user| user.to_proto())
            .collect();
    GetUsersResponse { users, has_next_page: false }
}
fn get_by_username(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetUsersResponse {
    let visibility = match user {
        Some(_) => Visibility::ServerPublic,
        None => Visibility::GlobalPublic,
    };
    let users = schema::users::table
            .select(schema::users::all_columns)
            .filter(schema::users::visibility.eq(visibility.as_str_name()))
            .filter(schema::users::username.ilike(format!("{}%", request.username.unwrap())))
            .order(schema::users::created_at.desc())
            .limit(100)
            .offset((request.page.unwrap_or(0) * 100).into())
            .load::<models::User>(conn)
            .unwrap()
            .iter()
            .map(|user| user.to_proto())
            .collect();
    GetUsersResponse { users, has_next_page: false }
}
