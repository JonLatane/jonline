use diesel::*;
// use diesel::internal::operators_macro::FieldAliasMapper;
use diesel_full_text_search::{
    configuration::TsConfigurationByName, to_tsquery_with_search_config, TsVectorExtensions,
};
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::prefix_tsquery_text;
use crate::marshaling::*;
use crate::models;
use crate::models::MEDIA_REFERENCE_COLUMNS;
use crate::protos::UserListingType::*;
use crate::protos::*;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::follows;
use crate::schema::media;
use crate::schema::users;

const PAGE_SIZE: i64 = 1000;
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
            Ok(get_follow_requests(request.to_owned(), user, None, conn))
        }
        (Some(user), Some(FollowRequestsTextSearch), _, _) => Ok(get_follow_requests(
            request.to_owned(),
            user,
            Some(required_search_text(&request)?),
            conn,
        )),
        (None, Some(FollowRequests), _, _) => Ok(GetUsersResponse::default()),
        (None, Some(FollowRequestsTextSearch), _, _) => Ok(GetUsersResponse::default()),
        (_, Some(Following), _, Some(_)) => get_following(request.to_owned(), user, None, conn),
        (_, Some(FollowingTextSearch), _, Some(_)) => get_following(
            request.to_owned(),
            user,
            Some(required_search_text(&request)?),
            conn,
        ),
        (_, Some(Followers), _, Some(_)) => get_followers(request.to_owned(), user, None, conn),
        (_, Some(FollowersTextSearch), _, Some(_)) => get_followers(
            request.to_owned(),
            user,
            Some(required_search_text(&request)?),
            conn,
        ),
        (_, Some(Friends), _, Some(_)) => get_friends(request.to_owned(), user, None, conn),
        (_, Some(FriendsTextSearch), _, Some(_)) => get_friends(
            request.to_owned(),
            user,
            Some(required_search_text(&request)?),
            conn,
        ),
        (_, Some(UsersTextSearch), _, _) => Ok(get_all_users(
            request.to_owned(),
            user,
            Some(required_search_text(&request)?),
            conn,
        )),
        (_, _, Some(_), _) => Ok(get_by_username(request.to_owned(), user, conn)),
        (_, _, _, Some(_)) => get_by_user_id(request.to_owned(), user, conn),
        _ => Ok(get_all_users(request.to_owned(), user, None, conn)),
    }?;
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

// `request.search_text`, trimmed and required non-empty - used by every `*_TEXT_SEARCH`
// `UserListingType` (see `get_users`' dispatch match). Also rejects search_text that
// `prefix_tsquery_text` can't turn into anything (e.g. all punctuation), so every downstream
// caller can assume `prefix_tsquery_text` on the value returned here is always non-empty.
fn required_search_text(request: &GetUsersRequest) -> Result<&str, Status> {
    let search_text = request
        .search_text
        .as_deref()
        .map(str::trim)
        .filter(|search_text| !search_text.is_empty())
        .ok_or(Status::new(Code::InvalidArgument, "search_text_required"))?;
    if prefix_tsquery_text(search_text).is_empty() {
        return Err(Status::new(Code::InvalidArgument, "search_text_required"));
    }
    Ok(search_text)
}

fn get_all_users(
    request: GetUsersRequest,
    user: &Option<&models::User>,
    search_text: Option<&str>,
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
    let mut query = users::table
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
            models::USER_COLUMNS,
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
        .limit(PAGE_SIZE)
        .offset((request.page.unwrap_or(0) * 100).into())
        .into_boxed();

    if let Some(search_text) = search_text {
        let search_query = to_tsquery_with_search_config(
            TsConfigurationByName("english"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(users::search_text.matches(search_query));
    }

    let users = query
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
            user.to_proto(
                &follow.as_ref(),
                &target_follow.as_ref(),
                lookup.as_ref(),
                None,
            )
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
    search_text: Option<&str>,
    conn: &mut PgPooledConnection,
) -> GetUsersResponse {
    let target_follows = alias!(follows as target_follows);
    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_target_user_moderation =
        target_follows.field(follows::target_user_moderation);
    let target_follows_columns = target_follows.fields(follows::all_columns);
    let mut query = target_follows
        .inner_join(users::table.on(target_follows_user_id.eq(users::id)))
        .left_join(
            follows::table.on(follows::target_user_id
                .eq(users::id)
                .and(follows::user_id.nullable().eq(user.id))),
        )
        .left_join(media::table.on(media::id.nullable().eq(users::avatar_media_id.nullable())))
        .select((
            models::USER_COLUMNS,
            follows::all_columns.nullable(),
            target_follows_columns,
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(target_follows_target_user_id.eq(user.id).and(
            target_follows_target_user_moderation.eq(Moderation::Pending.to_string_moderation()),
        ))
        .order(users::created_at.desc())
        .limit(PAGE_SIZE)
        .offset((request.page.unwrap_or(0) * 100).into())
        .into_boxed();

    if let Some(search_text) = search_text {
        let search_query = to_tsquery_with_search_config(
            TsConfigurationByName("english"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(users::search_text.matches(search_query));
    }

    let users = query
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
            user.to_proto(
                &follow.as_ref(),
                &Some(target_follow),
                lookup.as_ref(),
                None,
            )
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
            models::USER_COLUMNS,
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
        .limit(PAGE_SIZE)
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
            user.to_proto(
                &follow.as_ref(),
                &target_follow.as_ref(),
                lookup.as_ref(),
                Some(conn),
            )
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
) -> Result<GetUsersResponse, Status> {
    let user_id = request.user_id.to_db_opt_id_or_err("user_id")?.unwrap();
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
            models::USER_COLUMNS,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .filter(users::id.eq(user_id))
        .order(users::created_at.desc())
        .limit(PAGE_SIZE)
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
            user.to_proto(
                &follow.as_ref(),
                &target_follow.as_ref(),
                lookup.as_ref(),
                Some(conn),
            )
        })
        .collect();
    Ok(GetUsersResponse {
        users,
        has_next_page: false,
    })
}

// Lists the users that the user identified by `request.user_id` follows.
fn get_following(
    request: GetUsersRequest,
    user: &Option<&models::User>,
    search_text: Option<&str>,
    conn: &mut PgPooledConnection,
) -> Result<GetUsersResponse, Status> {
    let target_user_id = request.to_owned().user_id.to_db_opt_id_or_err("user_id")?.unwrap();
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let (relationship_follows, target_follows) =
        alias!(follows as relationship_follows, follows as target_follows);
    let relationship_follows_user_id = relationship_follows.field(follows::user_id);
    let relationship_follows_target_user_id = relationship_follows.field(follows::target_user_id);
    let relationship_follows_target_user_moderation =
        relationship_follows.field(follows::target_user_moderation);

    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_columns = target_follows.fields(follows::all_columns);

    let mut query = relationship_follows
        .inner_join(users::table.on(relationship_follows_target_user_id.eq(users::id)))
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
            models::USER_COLUMNS,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(relationship_follows_user_id.eq(target_user_id))
        .filter(relationship_follows_target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .order(users::created_at.desc())
        .limit(PAGE_SIZE)
        .offset((request.page.unwrap_or(0) * 100).into())
        .into_boxed();

    if let Some(search_text) = search_text {
        let search_query = to_tsquery_with_search_config(
            TsConfigurationByName("english"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(users::search_text.matches(search_query));
    }

    let users = query
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
            user.to_proto(
                &follow.as_ref(),
                &target_follow.as_ref(),
                lookup.as_ref(),
                Some(conn),
            )
        })
        .collect();
    Ok(GetUsersResponse {
        users,
        has_next_page: false,
    })
}

// Lists the users that follow the user identified by `request.user_id`.
fn get_followers(
    request: GetUsersRequest,
    user: &Option<&models::User>,
    search_text: Option<&str>,
    conn: &mut PgPooledConnection,
) -> Result<GetUsersResponse, Status> {
    let target_user_id = request.to_owned().user_id.to_db_opt_id_or_err("user_id")?.unwrap();
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let (relationship_follows, target_follows) =
        alias!(follows as relationship_follows, follows as target_follows);
    let relationship_follows_user_id = relationship_follows.field(follows::user_id);
    let relationship_follows_target_user_id = relationship_follows.field(follows::target_user_id);
    let relationship_follows_target_user_moderation =
        relationship_follows.field(follows::target_user_moderation);

    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_columns = target_follows.fields(follows::all_columns);

    let mut query = relationship_follows
        .inner_join(users::table.on(relationship_follows_user_id.eq(users::id)))
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
            models::USER_COLUMNS,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(relationship_follows_target_user_id.eq(target_user_id))
        .filter(relationship_follows_target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .order(users::created_at.desc())
        .limit(PAGE_SIZE)
        .offset((request.page.unwrap_or(0) * 100).into())
        .into_boxed();

    if let Some(search_text) = search_text {
        let search_query = to_tsquery_with_search_config(
            TsConfigurationByName("english"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(users::search_text.matches(search_query));
    }

    let users = query
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
            user.to_proto(
                &follow.as_ref(),
                &target_follow.as_ref(),
                lookup.as_ref(),
                Some(conn),
            )
        })
        .collect();
    Ok(GetUsersResponse {
        users,
        has_next_page: false,
    })
}

// Lists the users who mutually follow (and are followed by) the user
// identified by `request.user_id`.
fn get_friends(
    request: GetUsersRequest,
    user: &Option<&models::User>,
    search_text: Option<&str>,
    conn: &mut PgPooledConnection,
) -> Result<GetUsersResponse, Status> {
    let target_user_id = request.to_owned().user_id.to_db_opt_id_or_err("user_id")?.unwrap();
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let (following_relationship, follower_relationship, target_follows) = alias!(
        follows as following_relationship,
        follows as follower_relationship,
        follows as target_follows
    );
    let following_relationship_user_id = following_relationship.field(follows::user_id);
    let following_relationship_target_user_id =
        following_relationship.field(follows::target_user_id);
    let following_relationship_target_user_moderation =
        following_relationship.field(follows::target_user_moderation);

    let follower_relationship_user_id = follower_relationship.field(follows::user_id);
    let follower_relationship_target_user_id =
        follower_relationship.field(follows::target_user_id);
    let follower_relationship_target_user_moderation =
        follower_relationship.field(follows::target_user_moderation);

    let target_follows_user_id = target_follows.field(follows::user_id);
    let target_follows_target_user_id = target_follows.field(follows::target_user_id);
    let target_follows_columns = target_follows.fields(follows::all_columns);

    let mut query = following_relationship
        .inner_join(users::table.on(following_relationship_target_user_id.eq(users::id)))
        .inner_join(follower_relationship.on(follower_relationship_user_id.eq(users::id)))
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
            models::USER_COLUMNS,
            follows::all_columns.nullable(),
            target_follows_columns.nullable(),
            MEDIA_REFERENCE_COLUMNS.nullable(),
        ))
        .filter(following_relationship_user_id.eq(target_user_id))
        .filter(following_relationship_target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(follower_relationship_target_user_id.eq(target_user_id))
        .filter(follower_relationship_target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(
            users::visibility
                .eq_any(visibilities)
                .or(users::id.nullable().eq(user.map(|u| u.id))),
        )
        .order(users::created_at.desc())
        .limit(PAGE_SIZE)
        .offset((request.page.unwrap_or(0) * 100).into())
        .into_boxed();

    if let Some(search_text) = search_text {
        let search_query = to_tsquery_with_search_config(
            TsConfigurationByName("english"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(users::search_text.matches(search_query));
    }

    let users = query
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
            user.to_proto(
                &follow.as_ref(),
                &target_follow.as_ref(),
                lookup.as_ref(),
                Some(conn),
            )
        })
        .collect();
    Ok(GetUsersResponse {
        users,
        has_next_page: false,
    })
}
