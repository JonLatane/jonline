use diesel::*;
use tonic::Status;

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
) -> Result<GetUsersResponse, Status> {
    println!("GetUsers called");
    let response = match request.to_owned().username {
        Some(_) => get_by_username(request.to_owned(), user, conn),
        None => match request.to_owned().user_id {
            Some(_) => get_by_user_id(request.to_owned(), user, conn),
            None => get_all_users(request.to_owned(), user, conn),
        },
    };
    println!("GetUsers::request: {:?}, response: {:?}", request, response);
    Ok(response)
}

fn get_all_users(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetUsersResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();
    let users = users::table
        .select(users::all_columns)
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
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
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();
    let users = users::table
        .select(users::all_columns)
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
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

fn get_by_user_id(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetUsersResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();
    let users = users::table
        .select(users::all_columns)
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )        .filter(users::id.eq(request.user_id.unwrap().to_db_id().unwrap()))
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
