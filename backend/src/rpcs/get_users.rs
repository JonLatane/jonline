use diesel::*;
use tonic::{Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::users;

// use super::validations::*;

pub fn get_users(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<Response<GetUsersResponse>, Status> {
    println!("GetUsers called");
    let response = match request.to_owned().username {
        Some(_) => get_by_username(request.to_owned(), user, conn),
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
    let users = users::table
        .select(users::all_columns)
        .filter(users::visibility.eq(visibility.as_str_name()))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::User>(conn)
        .unwrap()
        .iter()
        .map(|user| user.to_proto())
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
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
    let users = users::table
        .select(users::all_columns)
        .filter(users::visibility.eq(visibility.as_str_name()))
        .filter(users::username.ilike(format!("{}%", request.username.unwrap())))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::User>(conn)
        .unwrap()
        .iter()
        .map(|user| user.to_proto())
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}
