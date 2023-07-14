use std::cmp::min;

use diesel::*;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::models;
use crate::protos::*;
use crate::schema::{follows, group_posts, groups, memberships, posts, users};

use super::validations::PASSING_MODERATIONS;

// use super::validations::*;

pub fn get_posts(
    request: GetPostsRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetPostsResponse, Status> {
    // log::info!("GetPosts called");
    // let req: GetPostsRequest = request.into_inner();
    let result = match (
        request.listing_type(),
        request.to_owned().post_id,
        request.to_owned().author_user_id,
    ) {
        (_, _, Some(user_id)) => {
            get_user_posts(user_id.to_string().to_db_id_or_err("user_id")?, &user, conn)
        }
        (PostListingType::MyGroupsPosts, _, _) => get_my_group_posts(
            &user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            conn,
        ),
        (PostListingType::FollowingPosts, _, _) => get_following_posts(
            &user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            conn,
        ),
        (PostListingType::GroupPosts, _, _) => get_group_posts(
            request
                .to_owned()
                .group_id
                .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
                .to_db_id_or_err("group_id")?,
            &user,
            vec![Moderation::Unmoderated, Moderation::Approved],
            conn,
        )?,
        (PostListingType::GroupPostsPendingModeration, _, _) => get_group_posts(
            request
                .to_owned()
                .group_id
                .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
                .to_db_id_or_err("group_id")?,
            &Some(user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?),
            vec![Moderation::Pending],
            conn,
        )?,
        (_, Some(post_id), _) => match request.reply_depth {
            None | Some(0) => get_by_post_id(&user, &post_id, conn)?,
            Some(reply_depth) => get_replies_to_post_id(&user, &post_id, reply_depth, conn)?,
        },
        (_, None, _) => get_public_and_following_posts(&user, conn),
    };
    // log::info!("GetPosts::request: {:?}, result: {:?}", request, result);
    Ok(GetPostsResponse { posts: result })
}

fn get_by_post_id(
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
        ))
        .filter(posts::id.eq(post_db_id))
        .get_result::<(models::Post, Option<String>)>(conn)
        .map(|(post, username)| post.to_proto(username.to_owned()));

    match result {
        Ok(post) => match (post.visibility(), user) {
            (Visibility::GlobalPublic, _) => Ok(vec![post]),
            (Visibility::ServerPublic, Some(_)) => Ok(vec![post]),
            _ => Err(Status::new(Code::NotFound, "post_not_found")),
        },
        Err(_) => Err(Status::new(Code::NotFound, "post_not_found")),
    }
}

fn get_public_and_following_posts(user: &Option<models::User>, conn: &mut PgPooledConnection) -> Vec<Post> {
    let public_visibilities = public_string_visibilities(user);
    let public = posts::visibility.eq_any(public_visibilities);
    let limited_to_followers = posts::visibility.eq(Visibility::Limited.to_string_visibility())
        .and(follows::user_id.eq(user.as_ref().map(|u| u.id).unwrap_or(0)));
    posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .left_join(
            follows::table.on(posts::user_id
                .eq(follows::target_user_id.nullable())
                .and(follows::user_id.eq(user.as_ref().map(|u| u.id).unwrap_or(0)))),
        )
        .select((
            posts::all_columns,
            users::username.nullable(),
        ))
        // .filter(posts::visibility.eq_any(visibilities))
        .filter(public.or(limited_to_followers))
        .filter(posts::parent_post_id.is_null())
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}

fn get_my_group_posts(user: &models::User, conn: &mut PgPooledConnection) -> Vec<Post> {
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
                posts::all_columns,
                users::username.nullable(),
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
            .load::<(models::Post, Option<String>)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username)| post.to_proto(username.to_owned()))
            .collect();
    }
    memberships::table
        .inner_join(groups::table.on(memberships::group_id.eq(groups::id)))
        .inner_join(group_posts::table.on(group_posts::group_id.eq(groups::id)))
        .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            posts::all_columns,
            users::username.nullable(),
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
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}

fn get_group_posts(
    group_id: i64,
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
                posts::all_columns,
                users::username.nullable(),
                group_posts::all_columns,
            ))
            .filter(group_posts::group_id.eq(group_id))
            .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
            .filter(posts::visibility.eq(Visibility::GlobalPublic.as_str_name()))
            .filter(posts::context.eq(PostContext::Post.as_str_name()))
            .order(posts::created_at.desc())
            .limit(100)
            .load::<(models::Post, Option<String>, models::GroupPost)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username, group_post)| {
                post.to_group_proto(username.to_owned(), Some(group_post))
            })
            .collect::<Vec<Post>>(),
        (Visibility::GlobalPublic, Some(_)) => group_posts::table
            .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .select((
                posts::all_columns,
                users::username.nullable(),
                group_posts::all_columns,
            ))
            .filter(group_posts::group_id.eq(group_id))
            .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
            .filter(posts::visibility.eq_any(vec![Visibility::GlobalPublic.as_str_name(), Visibility::ServerPublic.as_str_name()]))
            .filter(posts::context.eq(PostContext::Post.as_str_name()))
            .order(posts::created_at.desc())
            .limit(100)
            .load::<(models::Post, Option<String>, models::GroupPost)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username, group_post)| {
                post.to_group_proto(username.to_owned(), Some(group_post))
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
                    load_group_posts(group_id, moderations, conn)
                }
                _ => load_group_posts(group_id, moderations, conn),
            }
        }
        _ => return Err(Status::new(Code::NotFound, "group_not_found")),
    };
    Ok(result)
}

fn load_group_posts(
    group_id: i64,
    moderations: Vec<Moderation>,
    conn: &mut PgPooledConnection,
) -> Vec<Post> {
    group_posts::table
        .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            posts::all_columns,
            users::username.nullable(),
        ))
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
        .filter(posts::visibility.ne(Visibility::Private.as_str_name()))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect::<Vec<Post>>()
}

fn get_user_posts(
    user_id: i64,
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
            posts::all_columns,
            users::username.nullable(),
        ))
        .filter(posts::visibility.eq_any(visibilities))
        // .filter(posts::parent_post_id.is_null())
        .filter(posts::user_id.eq(user_id))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::last_activity_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}

fn get_following_posts(user: &models::User, conn: &mut PgPooledConnection) -> Vec<Post> {
    follows::table
        .inner_join(posts::table.on(follows::target_user_id.nullable().eq(posts::user_id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((
            posts::all_columns,
            users::username.nullable(),
        ))
        .filter(follows::user_id.eq(user.id))
        .filter(follows::target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(posts::visibility.eq_any(
            vec![Visibility::ServerPublic, Visibility::GlobalPublic].to_string_visibilities(),
        ))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}
fn get_replies_to_post_id(
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
            posts::all_columns,
            users::username.nullable(),
        ))
        .filter(posts::visibility.eq(Visibility::GlobalPublic.as_str_name()))
        .filter(posts::parent_post_id.eq(post_db_id))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect();
    if reply_depth > 1 {
        let extended_result: Vec<Post> = result
            .iter()
            .map(|post| {
                if post.reply_count == 0 {
                    return post.clone();
                }
                let replies =
                    get_replies_to_post_id(_user, &post.id, min(reply_depth - 1, 1), conn);
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
