use std::cmp::min;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::*;

use super::validations::PASSING_MODERATIONS;

// use super::validations::*;

pub fn get_events(
    request: GetEventsRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetEventsResponse, Status> {
    // log::info!("GetPosts called");
    // let req: GetPostsRequest = request.into_inner();
    let result: Vec<Event> = match (
        request.listing_type(),
        request.to_owned().event_id,
        request.to_owned().event_instance_id,
        request.to_owned().author_user_id,
    ) {
        _ => get_applicable_events(&user, conn, request.time_filter),
        // (_, _, Some(user_id)) => {
        //     get_user_posts(user_id.to_string().to_db_id_or_err("user_id")?, &user, conn)
        // }
        // (EventListingType::MyGroupsPosts, _, _) => get_my_group_posts(
        //     &user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
        //     conn,
        // ),
        // (EventListingType::FollowingPosts, _, _) => get_following_posts(
        //     &user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
        //     conn,
        // ),
        // (EventListingType::GroupPosts, _, _) => get_group_posts(
        //     request
        //         .to_owned()
        //         .group_id
        //         .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
        //         .to_db_id_or_err("group_id")?,
        //     &user,
        //     vec![Moderation::Unmoderated, Moderation::Approved],
        //     conn,
        // )?,
        // (EventListingType::GroupPostsPendingModeration, _, _) => get_group_posts(
        //     request
        //         .to_owned()
        //         .group_id
        //         .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
        //         .to_db_id_or_err("group_id")?,
        //     &Some(user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?),
        //     vec![Moderation::Pending],
        //     conn,
        // )?,
        // (_, Some(post_id), _) => match request.reply_depth {
        //     None | Some(0) => get_by_post_id(&user, &post_id, conn)?,
        //     Some(reply_depth) => get_replies_to_post_id(&user, &post_id, reply_depth, conn)?,
        // },
        // (_, None, _) => get_top_posts(&user, conn),
    };
    // log::info!("GetPosts::request: {:?}, result: {:?}", request, result);
    Ok(GetEventsResponse { events: result })
}

fn get_applicable_events(
    user: &Option<models::User>,
    conn: &mut PgPooledConnection,
    filter: Option<TimeFilter>,
) -> Vec<Event> {
    let public_visibilities = match user {
        Some(_) => vec![Visibility::GlobalPublic, Visibility::ServerPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .to_string_visibilities();
    let event_posts = alias!(posts as event_posts);
    let _instance_posts = alias!(posts as instance_posts);
    let event_users = alias!(users as event_users);
    let _instance_users = alias!(users as instance_users);

    let public = event_posts
        .field(posts::visibility)
        .eq_any(public_visibilities);
    let limited_to_followers = event_posts
        .field(posts::visibility)
        .eq(Visibility::Limited.to_string_visibility())
        .and(follows::user_id.eq(user.as_ref().map(|u| u.id).unwrap_or(0)));
    event_instances::table
        .inner_join(events::table.on(events::id.eq(event_instances::event_id)))
        .inner_join(event_posts.on(event_posts.field(posts::id).eq(events::post_id)))
        .left_join(
            event_users.on(event_posts
                .field(posts::user_id)
                .eq(event_users.field(users::id).nullable())),
        )
        // .left_join(
        //     instance_posts.on(event_instances::post_id.eq(instance_posts.field(posts::id))),
        //     // instance_posts.on(instance_posts
        //     //     .field(posts::id).nullable()
        //     //     .eq(event_instances::post_id)),
        // )
        // .left_join(instance_users.on(instance_posts.field(posts::user_id).eq(instance_users.field(users::id).nullable())))
        .left_join(
            follows::table.on(event_posts
                .field(posts::user_id)
                .eq(follows::target_user_id.nullable())
                .and(follows::user_id.nullable().eq(user.as_ref().map(|u| u.id).unwrap_or(0))))
        )
        .select((
            event_instances::all_columns,
            events::all_columns,
            event_posts.fields(posts::all_columns),
            event_users.fields(users::all_columns).nullable(),
            // instance_posts.fields(posts::all_columns).nullable(),
            // instance_users.fields(users::all_columns).nullable(),
            event_posts.field(posts::preview).is_not_null(),
            // instance_posts.field(posts::preview).is_not_null(),
        ))
        .filter(public.or(limited_to_followers))
        .order(event_instances::starts_at.desc())
        .limit(100)
        .load::<(
            models::EventInstance,
            models::Event,
            models::Post,
            Option<models::User>,
            // Option<models::Post>,
            // Option<models::User>,
            bool,
            // bool,
        )>(conn)
        .unwrap()
        .iter()
        .map(
            |(
                instance,
                event,
                event_post,
                event_user,
                // instance_post,
                // instance_user,
                has_event_preview,
                // has_instance_preview,
            )| {
                event.to_proto(
                    &event_post,
                    event_user.as_ref(),
                    &vec![(instance, None, None)],
                )
            },
        )
        .collect()
    // posts::table
    //     .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
    //     .left_join(
    //         follows::table.on(posts::user_id
    //             .eq(follows::target_user_id.nullable())
    //             .and(follows::user_id.eq(user.as_ref().map(|u| u.id).unwrap_or(0)))),
    //     )
    //     .select((
    //         models::MINIMAL_POST_COLUMNS,
    //         users::username.nullable(),
    //         posts::preview.is_not_null(),
    //     ))
    //     // .filter(posts::visibility.eq_any(visibilities))
    //     .filter(public.or(limited_to_followers))
    //     .filter(posts::parent_post_id.is_null())
    //     .filter(posts::context.eq(PostContext::Post.as_str_name()))
    //     .order(posts::created_at.desc())
    //     .limit(100)
    //     .load::<(models::MinimalPost, Option<String>, bool)>(conn)
    //     .unwrap()
    //     .iter()
    //     .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
    //     .collect()
}

//TODO Update below copypasta

fn _get_by_post_id(
    user: &Option<models::User>,
    post_id: &str,
    conn: &mut PgPooledConnection,
) -> Result<Vec<Post>, Status> {
    let post_db_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => return Err(Status::new(Code::InvalidArgument, "post_id_invalid")),
    };
    let result = posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            posts::all_columns,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        .filter(posts::id.eq(post_db_id))
        .get_result::<(models::Post, Option<String>, bool)>(conn)
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), &has_preview));

    match result {
        Ok(post) => match (post.visibility(), user) {
            (Visibility::GlobalPublic, _) => Ok(vec![post]),
            (Visibility::ServerPublic, Some(_)) => Ok(vec![post]),
            _ => Err(Status::new(Code::NotFound, "post_not_found")),
        },
        Err(_) => Err(Status::new(Code::NotFound, "post_not_found")),
    }
}

fn _get_top_posts(user: &Option<models::User>, conn: &mut PgPooledConnection) -> Vec<Post> {
    let public_visibilities = match user {
        Some(_) => vec![Visibility::GlobalPublic, Visibility::ServerPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .to_string_visibilities();
    let public = posts::visibility.eq_any(public_visibilities);
    let limited_to_followers = posts::visibility
        .eq(Visibility::Limited.to_string_visibility())
        .and(follows::user_id.eq(user.as_ref().map(|u| u.id).unwrap_or(0)));
    posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .left_join(
            follows::table.on(posts::user_id
                .eq(follows::target_user_id.nullable())
                .and(follows::user_id.eq(user.as_ref().map(|u| u.id).unwrap_or(0)))),
        )
        .select((
            models::MINIMAL_POST_COLUMNS,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        // .filter(posts::visibility.eq_any(visibilities))
        .filter(public.or(limited_to_followers))
        .filter(posts::parent_post_id.is_null())
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>, bool)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
        .collect()
}

fn _get_my_group_posts(user: &models::User, conn: &mut PgPooledConnection) -> Vec<Post> {
    let is_admin = user
        .permissions
        .to_proto_permissions()
        .contains(&Permission::Admin);
    if is_admin {
        return memberships::table
            .inner_join(groups::table.on(memberships::group_id.eq(groups::id)))
            .inner_join(group_posts::table.on(group_posts::group_id.eq(groups::id)))
            .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .select((
                models::MINIMAL_POST_COLUMNS,
                users::username.nullable(),
                posts::preview.is_not_null(),
            ))
            .filter(memberships::user_id.eq(user.id))
            .filter(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
            .filter(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
            .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
            .filter(posts::visibility.ne(Visibility::Private.as_str_name()))
            .filter(posts::context.eq(PostContext::Post.as_str_name()))
            .order(posts::id.desc())
            .distinct_on(posts::id)
            .limit(100)
            .load::<(models::MinimalPost, Option<String>, bool)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
            .collect();
    }
    memberships::table
        .inner_join(groups::table.on(memberships::group_id.eq(groups::id)))
        .inner_join(group_posts::table.on(group_posts::group_id.eq(groups::id)))
        .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            models::MINIMAL_POST_COLUMNS,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        .filter(memberships::user_id.eq(user.id))
        .filter(
            memberships::permissions.has_any_key(
                vec![Permission::ViewPosts, Permission::Admin].to_string_permissions(),
            ),
        )
        .filter(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
        .filter(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
        .filter(posts::visibility.ne(Visibility::Private.as_str_name()))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::id.desc())
        .distinct_on(posts::id)
        .limit(100)
        .load::<(models::MinimalPost, Option<String>, bool)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
        .collect()
}

fn _get_group_posts(
    group_id: i32,
    user: &Option<models::User>,
    moderations: Vec<Moderation>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<Post>, Status> {
    let group = models::get_group(group_id, conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;
    let result: Vec<Post> = match (group.visibility.to_proto_visibility().unwrap(), user) {
        (Visibility::GlobalPublic, None) => group_posts::table
            .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .select((
                models::MINIMAL_POST_COLUMNS,
                users::username.nullable(),
                posts::preview.is_not_null(),
                group_posts::all_columns,
            ))
            .filter(group_posts::group_id.eq(group_id))
            .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
            .filter(posts::visibility.eq(Visibility::GlobalPublic.as_str_name()))
            .filter(posts::context.eq(PostContext::Post.as_str_name()))
            .order(posts::created_at.desc())
            .limit(100)
            .load::<(models::MinimalPost, Option<String>, bool, models::GroupPost)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username, has_preview, group_post)| {
                post.to_group_proto(username.to_owned(), has_preview, Some(group_post))
            })
            .collect::<Vec<Post>>(),
        (Visibility::GlobalPublic, Some(_)) => group_posts::table
            .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .select((
                models::MINIMAL_POST_COLUMNS,
                users::username.nullable(),
                posts::preview.is_not_null(),
                group_posts::all_columns,
            ))
            .filter(group_posts::group_id.eq(group_id))
            .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
            .filter(posts::visibility.eq_any(vec![
                Visibility::GlobalPublic.as_str_name(),
                Visibility::ServerPublic.as_str_name(),
            ]))
            .filter(posts::context.eq(PostContext::Post.as_str_name()))
            .order(posts::created_at.desc())
            .limit(100)
            .load::<(models::MinimalPost, Option<String>, bool, models::GroupPost)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username, has_preview, group_post)| {
                post.to_group_proto(username.to_owned(), has_preview, Some(group_post))
            })
            .collect::<Vec<Post>>(),
        (_, None) => return Err(Status::new(Code::NotFound, "group_not_found")),
        (Visibility::ServerPublic, Some(user)) => {
            match group
                .default_membership_moderation
                .to_proto_moderation()
                .unwrap()
            {
                Moderation::Pending => {
                    let membership = models::get_membership(group_id, user.id, conn).ok();
                    // log::info!("membership: {:?}", membership);
                    if !membership.map(|m| m.passes()).unwrap_or(false) {
                        return Err(Status::new(Code::PermissionDenied, "not_a_member"));
                    }
                    _load_group_posts(group_id, moderations, conn)
                }
                _ => _load_group_posts(group_id, moderations, conn),
            }
        }
        _ => return Err(Status::new(Code::NotFound, "group_not_found")),
    };
    Ok(result)
}

fn _load_group_posts(
    group_id: i32,
    moderations: Vec<Moderation>,
    conn: &mut PgPooledConnection,
) -> Vec<Post> {
    group_posts::table
        .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            models::MINIMAL_POST_COLUMNS,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
        .filter(posts::visibility.ne(Visibility::Private.as_str_name()))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>, bool)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
        .collect::<Vec<Post>>()
}

fn _get_user_posts(
    user_id: i32,
    current_user: &Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Vec<Post> {
    let visibilities = match current_user {
        Some(_) => vec![Visibility::GlobalPublic, Visibility::ServerPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .to_string_visibilities();
    posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            models::MINIMAL_POST_COLUMNS,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        .filter(posts::visibility.eq_any(visibilities))
        // .filter(posts::parent_post_id.is_null())
        .filter(posts::user_id.eq(user_id))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::last_activity_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>, bool)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
        .collect()
}

fn _get_following_posts(user: &models::User, conn: &mut PgPooledConnection) -> Vec<Post> {
    follows::table
        .inner_join(posts::table.on(follows::target_user_id.nullable().eq(posts::user_id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            models::MINIMAL_POST_COLUMNS,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        .filter(follows::user_id.eq(user.id))
        .filter(follows::target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(posts::visibility.eq_any(
            vec![Visibility::ServerPublic, Visibility::GlobalPublic].to_string_visibilities(),
        ))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>, bool)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
        .collect()
}
fn _get_replies_to_post_id(
    _user: &Option<models::User>,
    post_id: &str,
    reply_depth: u32,
    conn: &mut PgPooledConnection,
) -> Result<Vec<Post>, Status> {
    let post_db_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => {
            return Err(Status::new(
                Code::InvalidArgument,
                "replies_to_post_id_invalid",
            ))
        }
    };
    let result: Vec<Post> = posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            models::MINIMAL_POST_COLUMNS,
            users::username.nullable(),
            posts::preview.is_not_null(),
        ))
        .filter(posts::visibility.eq(Visibility::GlobalPublic.as_str_name()))
        .filter(posts::parent_post_id.eq(post_db_id))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>, bool)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username, has_preview)| post.to_proto(username.to_owned(), has_preview))
        .collect();
    if reply_depth > 1 {
        let extended_result: Vec<Post> = result
            .iter()
            .map(|post| {
                if post.reply_count == 0 {
                    return post.clone();
                }
                let replies =
                    _get_replies_to_post_id(_user, &post.id, min(reply_depth - 1, 1), conn);
                Post {
                    replies: replies.unwrap().into(),
                    ..post.clone()
                }
            })
            .collect();
        return Ok(extended_result);
    }
    Ok(result)
}
