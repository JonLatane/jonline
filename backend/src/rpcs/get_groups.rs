use diesel::dsl::count;
use diesel::*;
use tonic::{Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{groups, memberships};

//TODO: Use GROUP BY queries to get counts. Or make it more efficient in some way.

pub fn get_groups(
    request: GetGroupsRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<Response<GetGroupsResponse>, Status> {
    println!("GetGroups called");
    let response = match request.to_owned().group_name {
        Some(_) => get_by_name(request.to_owned(), user, conn),
        None => get_all_groups(request.to_owned(), user, conn),
    };
    println!(
        "GetGroups::request: {:?}, response: {:?}",
        request, response
    );
    Ok(Response::new(response))
}

fn get_all_groups(
    request: GetGroupsRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetGroupsResponse {
    let visibility = match user {
        Some(_) => Visibility::ServerPublic,
        None => Visibility::GlobalPublic,
    };

    let groups = groups::table
        .select(groups::all_columns)
        .filter(groups::visibility.eq(visibility.as_str_name()))
        // .filter(groups::name.ilike(format!("{}%", request.group_name.unwrap())))
        .order(groups::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::Group>(conn)
        .unwrap()
        .iter()
        .map(|group| {
            let member_count = memberships::table
                .select(count(memberships::id))
                .filter(memberships::group_id.eq(group.id))
                // .filter(memberships::status.eq("member"))
                .first::<i64>(conn)
                .unwrap();
            group.to_proto(member_count as i32)
        })
        .collect();
    GetGroupsResponse {
        groups,
        has_next_page: false,
    }
}
fn get_by_name(
    request: GetGroupsRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetGroupsResponse {
    let visibility = match user {
        Some(_) => Visibility::ServerPublic,
        None => Visibility::GlobalPublic,
    };
    let groups = groups::table
        .select(groups::all_columns)
        .filter(groups::visibility.eq(visibility.as_str_name()))
        .filter(groups::name.ilike(format!("{}%", request.group_name.unwrap())))
        .order(groups::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::Group>(conn)
        .unwrap()
        .iter()
        .map(|group| {
            let member_count = memberships::table
                .select(count(memberships::id))
                .filter(memberships::group_id.eq(group.id))
                // .filter(memberships::status.eq("member"))
                .first::<i64>(conn)
                .unwrap();
            group.to_proto(member_count as i32)
        })
        .collect();
    GetGroupsResponse {
        groups,
        has_next_page: false,
    }
}
