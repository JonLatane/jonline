use diesel::*;
// use diesel::internal::operators_macro::FieldAliasMapper;
use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::MEDIA_REFERENCE_COLUMNS;
use crate::protos::UserListingType::*;
use crate::protos::*;
use crate::schema::follows;
use crate::schema::media;
use crate::schema::users;

pub fn get_users(
    request: GetUsersRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetUsersResponse, Status> {
    log::info!("GetUsers::request: {:?}", request);
    let response = match (
        &user,
        request.to_owned().listing_type.to_proto_user_listing_type(),
        request.to_owned().username,
        request.to_owned().user_id,
    ) {
        (Some(user), Some(FollowRequests), _, _) => {
            get_follow_requests(request.to_owned(), user, conn)
        }
        (None, Some(FollowRequests), _, _) => GetUsersResponse::default(),
        (_, _, Some(_), _) => get_by_username(request.to_owned(), user, conn),
        (_, _, _, Some(_)) => get_by_user_id(request.to_owned(), user, conn),
        _ => get_all_users(request.to_owned(), user, conn),
    };
    // let response = match request.to_owned().username {
    //     Some(_) => get_by_username(request.to_owned(), user, conn),
    //     None => match request.to_owned().user_id {
    //         Some(_) => get_by_user_id(request.to_owned(), user, conn),
    //         None => get_all_users(request.to_owned(), user, conn),
    //     },
    // };
    // log::info!("GetUsers::request: {:?}, response: {:?}", request, response);
    log::info!(
        "GetUsers::request: {:?}, response_length: {:?}",
        request,
        response.users.len()
    );
    Ok(response)
}

fn get_all_users(
    request: GetUsersRequest,
    user: &Option<&models::User>,
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
            target_follows.on(target_follows_user_id.eq(users::id).and(
                target_follows_target_user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id)),
            )),
        )
        .left_join(media::table.on(media::id.nullable().eq(users::avatar_media_id.nullable())))
        .select((
            users::all_columns,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(
            models::User,
            Option<models::Follow>,
            Option<models::Follow>,
            Option<models::MediaReference>,
        )>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow, media_reference)| {
            let lookup = media_reference.to_media_lookup();
            user.to_proto(&follow.as_ref(), &target_follow.as_ref(), lookup.as_ref())
        })
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}

fn get_follow_requests(
    request: GetUsersRequest,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> GetUsersResponse {
    let target_follows = alias!(follows as target_follows);
    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_target_user_moderation =
        target_follows.field(follows::target_user_moderation);
    let target_follows_columns = target_follows.fields(follows::all_columns);
    let users = target_follows
        .inner_join(users::table.on(target_follows_user_id.eq(users::id)))
        .left_join(
            follows::table.on(follows::target_user_id
                .eq(users::id)
                .and(follows::user_id.nullable().eq(user.id))),
        )
        .left_join(media::table.on(media::id.nullable().eq(users::avatar_media_id.nullable())))
        .select((
            users::all_columns,
            follows::all_columns.nullable(),
            target_follows_columns,
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(target_follows_target_user_id.eq(user.id).and(
            target_follows_target_user_moderation.eq(Moderation::Pending.to_string_moderation()),
        ))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(
            models::User,
            Option<models::Follow>,
            models::Follow,
            Option<models::MediaReference>,
        )>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow, media_reference)| {
            let lookup = media_reference.to_media_lookup();
            user.to_proto(&follow.as_ref(), &Some(target_follow), lookup.as_ref())
        })
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}

fn get_by_username(
    request: GetUsersRequest,
    user: &Option<&models::User>,
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

    let has_follow_relationship = follows::user_id
        .is_not_null()
        .or(target_follows_user_id.is_not_null());
    let is_self = users::id.nullable().eq(user.as_ref().map(|u| u.id));
    let users = users::table
        .left_join(
            follows::table.on(follows::target_user_id
                .eq(users::id)
                .and(follows::user_id.nullable().eq(user.as_ref().map(|u| u.id)))),
        )
        .left_join(
            target_follows.on(target_follows_user_id.eq(users::id).and(
                target_follows_target_user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id)),
            )),
        )
        .left_join(media::table.on(media::id.nullable().eq(users::avatar_media_id.nullable())))
        .select((
            users::all_columns,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(is_self)
                .or(has_follow_relationship),
        )
        // .filter(users::username.ilike(format!("{}%", request.username.unwrap())))
        .filter(users::username.eq(request.username.unwrap()))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(
            models::User,
            Option<models::Follow>,
            Option<models::Follow>,
            Option<models::MediaReference>,
        )>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow, media_reference)| {
            let lookup = media_reference.to_media_lookup();
            user.to_proto(&follow.as_ref(), &target_follow.as_ref(), lookup.as_ref())
        })
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}

fn get_by_user_id(
    request: GetUsersRequest,
    user: &Option<&models::User>,
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
            target_follows.on(target_follows_user_id.eq(users::id).and(
                target_follows_target_user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id)),
            )),
        )
        .left_join(media::table.on(media::id.nullable().eq(users::avatar_media_id.nullable())))
        .select((
            users::all_columns,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .filter(users::id.eq(request.user_id.unwrap().to_db_id().unwrap()))
        .order(users::created_at.desc())
        .limit(100)
        .offset((request.page.unwrap_or(0) * 100).into())
        .load::<(
            models::User,
            Option<models::Follow>,
            Option<models::Follow>,
            Option<models::MediaReference>,
        )>(conn)
        .unwrap()
        .iter()
        .map(|(user, follow, target_follow, media_reference)| {
            let lookup = media_reference.to_media_lookup();
            user.to_proto(&follow.as_ref(), &target_follow.as_ref(), lookup.as_ref())
        })
        .collect();
    GetUsersResponse {
        users,
        has_next_page: false,
    }
}
