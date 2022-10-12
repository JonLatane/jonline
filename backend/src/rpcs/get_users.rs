use diesel::*;
// use diesel::internal::operators_macro::FieldAliasMapper;
use tonic::Status;

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::protos::UserListingType::*;
use crate::schema::follows;
use crate::schema::users;

pub fn get_users(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetUsersResponse, Status> {
    println!("GetUsers called");
    let response = match (request.to_owned().listing_type.to_proto_user_listing_type(), request.to_owned().username, request.to_owned().user_id) {
        (Some(FollowRequests), _, _) => get_all_users(request.to_owned(), user, conn),
        (_, Some(_), _) => get_by_username(request.to_owned(), user, conn),
        (_, _, Some(_)) => get_by_user_id(request.to_owned(), user, conn),
        _ => get_all_users(request.to_owned(), user, conn),
    };
    // let response = match request.to_owned().username {
    //     Some(_) => get_by_username(request.to_owned(), user, conn),
    //     None => match request.to_owned().user_id {
    //         Some(_) => get_by_user_id(request.to_owned(), user, conn),
    //         None => get_all_users(request.to_owned(), user, conn),
    //     },
    // };
    println!("GetUsers::request: {:?}, response: {:?}", request, response);
    Ok(response)
}

fn get_all_users(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> GetUsersResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let target_follows = alias!(follows as target_follows);
    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_columns = target_follows.fields(follows::all_columns);
    let users = users::table
        .left_join(
            follows::table.on(follows::target_user_id
                .eq(users::id)
                .and(follows::user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .left_join(
            target_follows.on(target_follows_user_id
                .eq(users::id)
                .and(target_follows_target_user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .select((users::all_columns, follows::all_columns.nullable(), target_follows_columns.nullable()))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(models::User, Option<models::Follow>, Option<models::Follow>)>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow)| user.to_proto_with(&follow, &target_follow))
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}
fn get_by_username(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> GetUsersResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let target_follows = alias!(follows as target_follows);
    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_columns = target_follows.fields(follows::all_columns);
    let users = users::table
        .left_join(
            follows::table.on(follows::target_user_id
                .eq(users::id)
                .and(follows::user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .left_join(
            target_follows.on(target_follows_user_id
                .eq(users::id)
                .and(target_follows_target_user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .select((users::all_columns, follows::all_columns.nullable(), target_follows_columns.nullable()))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .filter(users::username.ilike(format!("{}%", request.username.unwrap())))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(models::User, Option<models::Follow>, Option<models::Follow>)>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow)| user.to_proto_with(&follow, &target_follow))
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}

fn get_by_user_id(
    request: GetUsersRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> GetUsersResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let target_follows = alias!(follows as target_follows);
    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_columns = target_follows.fields(follows::all_columns);
    let users = users::table
        .left_join(
            follows::table.on(follows::target_user_id
                .eq(users::id)
                .and(follows::user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .left_join(
            target_follows.on(target_follows_user_id
                .eq(users::id)
                .and(target_follows_target_user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .select((users::all_columns, follows::all_columns.nullable(), target_follows_columns.nullable()))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .filter(users::id.eq(request.user_id.unwrap().to_db_id().unwrap()))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(models::User, Option<models::Follow>, Option<models::Follow>)>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow)| user.to_proto_with(&follow, &target_follow))
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}
