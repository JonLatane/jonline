use diesel::*;
use tonic::{Code, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::models;
use crate::protos::Moderation::*;
use crate::protos::Permission::ModeratePosts;
use crate::protos::*;
use crate::schema::{group_posts, groups, memberships, posts};

use super::validations::validate_group_permission;

// Get GroupPosts by either group_id+post_id or post_id alone.
// Use get_posts to get Posts (and associated GroupPosts) by group_id.
pub fn get_group_posts(
    request: GetGroupPostsRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetGroupPostsResponse, Status> {
    let query = group_posts::table
        .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
        .inner_join(groups::table.on(group_posts::group_id.eq(groups::id)))
        .left_join(memberships::table.on(memberships::group_id.eq(groups::id)))
        .select((
            group_posts::all_columns,
            posts::visibility,
            memberships::all_columns.nullable(),
        ));
    let results = match (request.group_id, request.post_id) {
        (None, Some(post_id)) => {
            let post_id = post_id.to_db_id_or_err("post_id")?;
            query
                .filter(group_posts::post_id.eq(post_id))
                .load::<(models::GroupPost, String, Option<models::Membership>)>(conn)
                .unwrap()
        }
        (Some(group_id), Some(post_id)) => {
            let group_id = group_id.to_db_id_or_err("group_id")?;
            let post_id = post_id.to_db_id_or_err("post_id")?;
            query
                .filter(
                    group_posts::group_id
                        .eq(group_id)
                        .and(group_posts::post_id.eq(post_id)),
                )
                .load::<(models::GroupPost, String, Option<models::Membership>)>(conn)
                .unwrap()
        }
        _ => return Err(Status::new(Code::InvalidArgument, "invalid_request")),
    };
    let filtered_results = results
        .iter()
        .filter_map(|(group_post, post_visibility, membership)| {
            let moderations = match (user.as_ref(), membership.as_ref()) {
                (Some(user), Some(membership)) => {
                    match validate_group_permission(&membership, &user, ModeratePosts) {
                        Ok(_) => vec![Unmoderated, Approved, Pending],
                        Err(_) => vec![Unmoderated, Approved],
                    }
                }
                _ => vec![Unmoderated, Approved],
            };
            match post_visibility.to_proto_visibility().unwrap() {
                Visibility::Unknown => return None,
                Visibility::Private => return None,
                Visibility::Limited => {
                    if !membership.as_ref().map(|m| m.passes()).unwrap_or(false) {
                        return None;
                    }
                }
                Visibility::GlobalPublic | Visibility::ServerPublic => {}
            };
            if moderations.contains(&group_post.group_moderation.to_proto_moderation().unwrap()) {
                return Some(group_post.to_proto());
            }
            None
        })
        .collect::<Vec<GroupPost>>();

    Ok(GetGroupPostsResponse {
        group_posts: filtered_results,
    })
}
