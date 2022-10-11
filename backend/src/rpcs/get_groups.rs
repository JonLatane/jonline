use diesel::*;
use tonic::Status;

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::groups;

//TODO: Use GROUP BY queries to get counts. Or make it more efficient in some way.

pub fn get_groups(
    request: GetGroupsRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<GetGroupsResponse, Status> {
    println!("GetGroups called");
    let response = match request.to_owned().group_id {
        Some(_) => get_by_id(request.to_owned(), user, conn),
        None => match request.to_owned().group_name {
            Some(_) => get_by_name(request.to_owned(), user, conn),
            None => get_all_groups(request.to_owned(), user, conn),
        },
    };
    println!(
        "GetGroups::request: {:?}, response: {:?}",
        request, response
    );
    Ok(response)
}

fn get_all_groups(
    request: GetGroupsRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetGroupsResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let groups = groups::table
        .select(groups::all_columns)
        .filter(groups::visibility.eq_any(visibilities))
        // .filter(groups::name.ilike(format!("{}%", request.group_name.unwrap())))
        .order(groups::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::Group>(conn)
        .unwrap()
        .iter()
        .map(|group| group.to_proto(&conn, &user))
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
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();
    let groups = groups::table
        .select(groups::all_columns)
        .filter(groups::visibility.eq_any(visibilities))
        .filter(groups::name.ilike(format!("{}%", request.group_name.unwrap())))
        .order(groups::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::Group>(conn)
        .unwrap()
        .iter()
        .map(|group| group.to_proto(&conn, &user))
        .collect();
    GetGroupsResponse {
        groups,
        has_next_page: false,
    }
}

fn get_by_id(
    request: GetGroupsRequest,
    user: Option<models::User>,
    conn: &PgPooledConnection,
) -> GetGroupsResponse {
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();
    let groups = groups::table
        .select(groups::all_columns)
        .filter(groups::visibility.eq_any(visibilities))
        .filter(
            groups::id.eq(request
                .group_id
                .unwrap()
                .to_db_id_or_err("group_id")
                .unwrap()),
        )
        .order(groups::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<models::Group>(conn)
        .unwrap()
        .iter()
        .map(|group| group.to_proto(&conn, &user))
        .collect();
    GetGroupsResponse {
        groups,
        has_next_page: false,
    }
}
