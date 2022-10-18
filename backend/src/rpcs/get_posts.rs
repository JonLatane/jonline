use diesel::*;
use tonic::{Code, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::logic::*;
use crate::schema::{follows, group_posts, groups, memberships, posts, users};

use super::validations::PASSING_MODERATIONS;

// use super::validations::*;

pub fn get_posts(
    request: GetPostsRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetPostsResponse, Status> {
    // println!("GetPosts called");
    // let req: GetPostsRequest = request.into_inner();
    let result = match (request.listing_type(), request.to_owned().post_id) {
        (PostListingType::MyGroupsPosts, _) => get_my_group_posts(
            &user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            conn,
        ),
        (PostListingType::FollowingPosts, _) => get_following_posts(
            &user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?,
            conn,
        ),
        (PostListingType::GroupPosts, _) => get_group_posts(
            request
                .to_owned()
                .group_id
                .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
                .to_db_id_or_err("group_id")?,
            &user,
            vec![Moderation::Unmoderated, Moderation::Approved],
            conn,
        )?,
        (PostListingType::GroupPostsPendingModeration, _) => get_group_posts(
            request
                .to_owned()
                .group_id
                .ok_or(Status::new(Code::InvalidArgument, "group_id_required"))?
                .to_db_id_or_err("group_id")?,
            &Some(user.ok_or(Status::new(Code::Unauthenticated, "must_be_logged_in"))?),
            vec![Moderation::Pending],
            conn,
        )?,
        (_, Some(post_id)) => match request.reply_depth {
            None | Some(0) => get_by_post_id(&user, &post_id, conn)?,
            _ => get_replies_to_post_id(&user, &post_id, conn)?,
        },
        (_, None) => get_all_posts(&user, conn),
    };
    println!("GetPosts::request: {:?}, result: {:?}", request, result);
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
        .select((posts::all_columns, users::username.nullable()))
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

fn get_all_posts(user: &Option<models::User>, conn: &mut PgPooledConnection) -> Vec<Post> {
    let visibilities = match user {
        Some(_) => vec![Visibility::GlobalPublic, Visibility::ServerPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .to_string_visibilities();
    posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
        .filter(posts::visibility.eq_any(visibilities))
        .filter(posts::parent_post_id.is_null())
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}

fn get_my_group_posts(user: &models::User, conn: &mut PgPooledConnection) -> Vec<Post> {
    let is_admin = user.permissions.to_proto_permissions().contains(&Permission::Admin);
    if is_admin {
        return memberships::table
            .inner_join(groups::table.on(memberships::group_id.eq(groups::id)))
            .inner_join(group_posts::table.on(group_posts::group_id.eq(groups::id)))
            .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
            .filter(memberships::user_id.eq(user.id))
            .filter(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
            .filter(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
            .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
            .filter(posts::visibility.ne("PRIVATE"))
            .order(posts::id.desc())
            .distinct_on(posts::id)
            .limit(100)
            .load::<(models::MinimalPost, Option<String>)>(conn)
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
        .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
        .filter(memberships::user_id.eq(user.id))
        .filter(memberships::permissions.has_any_key(vec![Permission::ViewPosts, Permission::Admin].to_string_permissions()))
        .filter(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
        .filter(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
        .filter(posts::visibility.ne("PRIVATE"))
        .order(posts::id.desc())
        .distinct_on(posts::id)
        .limit(100)
        .load::<(models::MinimalPost, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}

fn get_group_posts(
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
                                            .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
                                            .filter(group_posts::group_id.eq(group_id))
                                            .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
                                            .filter(posts::visibility.eq("GLOBAL_PUBLIC"))
                                            .order(posts::created_at.desc())
                                            .limit(100)
                                            .load::<(models::MinimalPost, Option<String>)>(conn)
                                            .unwrap()
                                            .iter()
                                            .map(|(post, username)| post.to_proto(username.to_owned()))
                                            .collect::<Vec<Post>>(),
        (Visibility::GlobalPublic, Some(_)) => group_posts::table
                                            .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
                                            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
                                            .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
                                            .filter(group_posts::group_id.eq(group_id))
                                            .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
                                            .filter(posts::visibility.eq_any(vec!["GLOBAL_PUBLIC", "SERVER_PUBLIC"]))
                                            .order(posts::created_at.desc())
                                            .limit(100)
                                            .load::<(models::MinimalPost, Option<String>)>(conn)
                                            .unwrap()
                                            .iter()
                                            .map(|(post, username)| post.to_proto(username.to_owned()))
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
                    if !membership.map(|m| m.passes()).unwrap_or(false) {
                        return Err(Status::new(Code::PermissionDenied, "not_a_member"));
                    }
                    load_group_posts(group_id, moderations, conn)
                }
                _ => load_group_posts(group_id, moderations, conn)
            }
        }
        _ => return Err(Status::new(Code::NotFound, "group_not_found")),
    };
    Ok(result)
}

fn load_group_posts(
    group_id: i32,
    moderations: Vec<Moderation>,
    conn: &mut PgPooledConnection,) -> Vec<Post> {
    group_posts::table
                                    .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
                                    .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
                                    .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
                                    .filter(group_posts::group_id.eq(group_id))
                                    .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
                                    .filter(posts::visibility.ne("PRIVATE"))
                                    .order(posts::created_at.desc())
                                    .limit(100)
                                    .load::<(models::MinimalPost, Option<String>)>(conn)
                                    .unwrap()
                                    .iter()
                                    .map(|(post, username)| post.to_proto(username.to_owned()))
                                    .collect::<Vec<Post>>()
}

fn get_following_posts(user: &models::User, conn: &mut PgPooledConnection) -> Vec<Post> {
    follows::table
        .inner_join(posts::table.on(follows::target_user_id.nullable().eq(posts::user_id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
        .filter(follows::user_id.eq(user.id))
        .filter(follows::target_user_moderation.eq_any(PASSING_MODERATIONS))
        .filter(posts::visibility.eq_any(
            vec![Visibility::ServerPublic, Visibility::GlobalPublic].to_string_visibilities(),
        ))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}
fn get_replies_to_post_id(
    _user: &Option<models::User>,
    post_id: &str,
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
    let result = posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
        .filter(posts::visibility.eq("GLOBAL_PUBLIC"))
        .filter(posts::parent_post_id.eq(post_db_id))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect();
    Ok(result)
}
