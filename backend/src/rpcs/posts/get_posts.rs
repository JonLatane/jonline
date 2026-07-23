use std::collections::HashMap;

use diesel::*;
use diesel_full_text_search::{
    configuration::TsConfigurationByName, to_tsquery_with_search_config, TsVectorExtensions,
};
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

const PAGE_SIZE: i64 = 200;
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
        (PostListingType::TextSearch, _, _) => get_search_posts(&request, &user.clone(), conn)?,
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
        (_, None, _) => get_public_and_following_posts(&request, &user, conn),
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
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
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

// `request.context()` defaults to `Post` (see `GetPostsRequest.context`'s proto doc comment).
// The `parent_post_id IS NULL` filter only makes sense for that default POST case - it's what
// keeps this a feed of top-level posts; a real REPLY always has a parent, so requesting REPLY
// context here (e.g. "browse all accessible replies") would otherwise always come back empty.
fn get_public_and_following_posts(
    request: &GetPostsRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Vec<MarshalablePost> {
    let context = request.context();

    let mut query = query_visible_posts!(user)
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
        .filter(posts::context.eq(context.as_str_name()))
        .filter(posts::user_id.is_not_null())
        .order(posts::created_at.desc())
        .limit(PAGE_SIZE)
        .into_boxed();

    if context == PostContext::Post {
        query = query.filter(posts::parent_post_id.is_null());
    }

    query
        .load::<(models::Post, Option<models::Author>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect()
}

// Full-text search across accessible posts' author username/real name, title, link, and content.
// Filters on (posts::context, posts::search_text) and, when scoped to an author, also
// posts::user_id - matching the composite GIN indexes added alongside the search_text column, so
// each of those filter combinations is served by a single index scan.
fn get_search_posts(
    request: &GetPostsRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalablePost>, Status> {
    let search_text = request
        .search_text
        .as_deref()
        .map(str::trim)
        .filter(|search_text| !search_text.is_empty())
        .ok_or(Status::new(Code::InvalidArgument, "search_text_required"))?;
    let prefix_query_text = prefix_tsquery_text(search_text);
    if prefix_query_text.is_empty() {
        return Err(Status::new(Code::InvalidArgument, "search_text_required"));
    }
    let author_user_id = request
        .author_user_id
        .as_ref()
        .map(|author_user_id| author_user_id.to_db_id_or_err("author_user_id"))
        .transpose()?;

    // Prefix (not just whole/stemmed lexeme) matching - see `prefix_tsquery_text`'s doc comment.
    // "simple" (not "english") to match posts_build_search_text's indexing config - see
    // 2026-07-23-012047_add_search_text_no_stopwords - otherwise a query for a stopword like
    // "about" would get stripped from the query side even though it's indexed on the document side.
    let search_query =
        to_tsquery_with_search_config(TsConfigurationByName("simple"), prefix_query_text);

    let mut query = query_visible_posts!(user)
        .filter(posts::context.eq(request.context().as_str_name()))
        .filter(posts::search_text.matches(search_query))
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
        .order(posts::created_at.desc())
        .limit(PAGE_SIZE)
        .into_boxed();

    if let Some(author_user_id) = author_user_id {
        query = query.filter(posts::user_id.eq(author_user_id));
    }

    let result: Vec<MarshalablePost> = query
        .load::<(models::Post, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?
        .iter()
        .map(|(post, author)| MarshalablePost(post.clone(), author.clone(), None, None, vec![]))
        .collect();

    Ok(result)
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
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
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
                    models::POST_COLUMNS,
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
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
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
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
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
    let mut replies_by_parent = get_replies_to_post_ids(user, &[post_db_id], reply_depth, conn)?;
    Ok(replies_by_parent.remove(&post_db_id).unwrap_or_default())
}

// Fetches replies to a batch of parent post ids, `reply_depth` levels deep, keyed
// by parent post id. Each depth level is a single query covering every post at
// that level (via `eq_any`), so getting replies `reply_depth` levels deep for any
// number of posts takes exactly `reply_depth` queries, not one query per post.
fn get_replies_to_post_ids(
    user: &Option<&models::User>,
    post_ids: &[i64],
    reply_depth: u32,
    conn: &mut PgPooledConnection,
) -> Result<HashMap<i64, Vec<MarshalablePost>>, Status> {
    if reply_depth == 0 || post_ids.is_empty() {
        return Ok(HashMap::new());
    }

    let level = query_visible_posts!(user)
        .filter(posts::parent_post_id.eq_any(post_ids))
        .filter(posts::user_id.is_not_null().or(posts::response_count.gt(0)))
        .select((models::POST_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
        .order(posts::created_at.desc())
        .limit(PAGE_SIZE)
        .load::<(models::Post, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_posts"))?;

    let child_ids: Vec<i64> = level.iter().map(|(post, _)| post.id).collect();
    let mut grandchildren = get_replies_to_post_ids(user, &child_ids, reply_depth - 1, conn)?;

    let mut replies_by_parent: HashMap<i64, Vec<MarshalablePost>> = HashMap::new();
    for (post, author) in level {
        let replies = grandchildren.remove(&post.id).unwrap_or_default();
        replies_by_parent
            .entry(post.parent_post_id.unwrap_or(0))
            .or_default()
            .push(MarshalablePost(post, author, None, None, replies));
    }

    Ok(replies_by_parent)
}
