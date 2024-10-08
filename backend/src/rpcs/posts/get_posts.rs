use std::cmp::min;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::marshaling::*;
use crate::models;
use crate::models::get_group;
use crate::models::get_membership;
use crate::protos::*;
use crate::rpcs::validate_group_permission;
use crate::schema::{follows, group_posts, memberships, posts, users};

use crate::rpcs::validations::PASSING_MODERATIONS;

const PAGE_SIZE: i64 = 1000;
pub fn get_posts(
    request: GetPostsRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetPostsResponse, Status> {
    let result = match (
        request.listing_type(),
        request.to_owned().post_id,
        request.to_owned().author_user_id,
    ) {
        (_, Some(post_id), _) => match request.reply_depth {
            None | Some(0) => get_by_post_id(&user, &post_id, conn)?,
            Some(reply_depth) => get_replies_to_post_id(&user, &post_id, reply_depth, conn)?,
        },
        (_, _, Some(_author_user_id)) => get_user_posts(request, &user.clone(), conn)?,
        (PostListingType::MyGroupsPosts, _, _) => get_my_group_posts(
            user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            conn,
        )?,
        (PostListingType::FollowingPosts, _, _) => get_following_posts(
            user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            conn,
        )?,
        (PostListingType::GroupPosts, _, _) => get_group_posts(
            request
                .to_owned()
                .group_id
                .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
                .to_db_id_or_err("group_id")?,
            &user.clone(),
            vec![Moderation::Unmoderated, Moderation::Approved],
            conn,
        )?,
        (PostListingType::GroupPostsPendingModeration, _, _) => {
            let binding = Some(
                user.clone()
                    .ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            );
            get_group_posts(
                request
                    .to_owned()
                    .group_id
                    .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
                    .to_db_id_or_err("group_id")?,
                &binding,
                vec![Moderation::Pending],
                conn,
            )?
        }
        (_, None, _) => get_public_and_following_posts(&user, conn),
    };

    Ok(GetPostsResponse {
        posts: convert_posts(&result, conn),
    })
}

macro_rules! query_visible_posts {
    ($user: expr) => {{
        posts::table
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .left_join(
                follows::table.on(posts::user_id
                    .eq(follows::target_user_id.nullable())
                    .and(follows::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0)))),
            )
            .left_join(group_posts::table.on(posts::id.eq(group_posts::post_id)))
            .left_join(
                memberships::table.on(memberships::user_id
                    .eq($user.as_ref().map(|u| u.id).unwrap_or(0))
                    .and(memberships::group_id.eq(group_posts::group_id))),
            )
            .filter(
                posts::visibility
                    .eq_any(public_string_visibilities($user))
                    .or(posts::visibility
                        .eq(Visibility::Limited.to_string_visibility())
                        .and(follows::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    .or(posts::visibility
                        .eq(Visibility::Limited.to_string_visibility())
                        .and(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
                        .and(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
                        .and(memberships::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    // .or(posts::visibility
                    //     .eq(Visibility::Private.to_string_visibility())
                    //     .and(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    .or(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))),
            )
            .distinct()
            .limit(PAGE_SIZE)
    }};
}

fn get_by_post_id(
    user: &Option<&models::User>,
    post_id: &str,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    let post_db_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => return Err(Status::new(Code::InvalidArgument, "post_id_invalid")),
    };
    let result: Vec<MarshalablePost> = query_visible_posts!(user)
        .filter(posts::id.eq(post_db_id))
        .select((posts::all_columns, models::AUTHOR_COLUMNS.nullable()))
        .load::<(models::Post, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect();

    if result.len() == 0 {
        return Err(Status::new(Code::NotFound, "post_not_found"));
    }

    Ok(result)
}

fn get_public_and_following_posts(
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Vec<MarshalablePost> {
    query_visible_posts!(user)
        .select((posts::all_columns, models::AUTHOR_COLUMNS.nullable()))
        .filter(posts::parent_post_id.is_null())
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .filter(posts::user_id.is_not_null())
        .order(posts::created_at.desc())
        .limit(PAGE_SIZE)
        .load::<(models::Post, Option<models::Author>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect()
}

fn get_my_group_posts(
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    // let is_admin = user
    //     .permissions
    //     .to_proto_permissions()
    //     .contains(&Permission::Admin);

    let result: Vec<MarshalablePost> = query_visible_posts!(&Some(user))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .filter(memberships::user_id.eq(user.id))
        .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
        .select((posts::all_columns, models::AUTHOR_COLUMNS.nullable()))
        .load::<(models::Post, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect();

    Ok(result)
}

fn get_group_posts(
    group_id: i64,
    user: &Option<&models::User>,
    moderations: Vec<Moderation>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    let group = get_group(group_id, conn);
    match group {
        Ok(group) => {
            let membership = user
                .map(|u| get_membership(group_id, u.id, conn).ok())
                .flatten();
            validate_group_permission(&group, &membership.as_ref(), user, Permission::ViewPosts)?;
            let group_post_users = alias!(users as group_post_users);
            let result: Vec<MarshalablePost> = query_visible_posts!(user)
                .left_join(
                    group_post_users.on(group_posts::user_id.eq(group_post_users.field(users::id))),
                )
                .filter(posts::context.eq(PostContext::Post.as_str_name()))
                .filter(group_posts::group_id.eq(group_id))
                .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
                .select((
                    posts::all_columns,
                    models::AUTHOR_COLUMNS.nullable(),
                    group_posts::all_columns.nullable(),
                    group_post_users.fields(models::AUTHOR_COLUMNS.nullable()),
                ))
                .load::<(
                    models::Post,
                    Option<models::Author>,
                    Option<models::GroupPost>,
                    Option<models::Author>,
                )>(conn)
                .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?
                .iter()
                .map(|(post, author, group_post, group_post_author)| {
                    MarshalablePost(
                        post.clone(),
                        author.clone(),
                        group_post.clone(),
                        group_post_author.clone(),
                        vec![],
                    )
                })
                .collect();

            Ok(result)
        }
        Err(_) => Err(Status::new(Code::NotFound, "group_not_found")),
    }
}

fn get_user_posts(
    request: GetPostsRequest,
    // user_id: i64,
    current_user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    let user_id = request
        .author_user_id
        .as_ref()
        .unwrap()
        .to_string()
        .to_db_id_or_err("user_id")?;

    let result: Vec<MarshalablePost> = query_visible_posts!(current_user)
        .filter(posts::context.eq(request.context().as_str_name()))
        .filter(posts::user_id.eq(user_id))
        .select((posts::all_columns, models::AUTHOR_COLUMNS.nullable()))
        .load::<(models::Post, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect();

    Ok(result)
}

fn get_following_posts(
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    let result: Vec<MarshalablePost> = query_visible_posts!(&Some(user))
        .filter(posts::context.eq(PostContext::Post.as_str_name()))
        .filter(follows::user_id.eq(user.id))
        .select((posts::all_columns, models::AUTHOR_COLUMNS.nullable()))
        .load::<(models::Post, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect();

    Ok(result)
}

fn get_replies_to_post_id(
    user: &Option<&models::User>,
    post_id: &str,
    reply_depth: u32,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    let post_db_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => {
            return Err(Status::new(
                Code::InvalidArgument,
                "replies_to_post_id_invalid",
            ))
        }
    };
    let result = query_visible_posts!(user)
        .filter(posts::parent_post_id.eq(post_db_id))
        .filter(posts::user_id.is_not_null().or(posts::response_count.gt(0)))
        .select((posts::all_columns, models::AUTHOR_COLUMNS.nullable()))
        .order(posts::created_at.desc())
        .limit(PAGE_SIZE)
        .load::<(models::Post, Option<models::Author>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, author)| {
            if reply_depth > 1 {
                let replies = get_replies_to_post_id(
                    user,
                    &post.id.to_proto_id(),
                    min(reply_depth - 1, 1),
                    conn,
                )
                .unwrap_or(vec![]);
                MarshalablePost(post.clone(), author.clone(), None, None, replies)
            } else {
                MarshalablePost(post.clone(), author.clone(), None, None, vec![])
            }
        })
        .collect();
    Ok(result)
}
