use diesel::*;
use tonic::Status;

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::models;
use crate::protos::Moderation::*;
use crate::protos::Permission::ModeratePosts;
use crate::protos::*;
use crate::schema::{group_posts, posts};

use super::validations::validate_group_permission;

// Get GroupPosts by either group_id+post_id or post_id alone.
// Use get_posts to get Posts (and associated GroupPosts) by group_id.
pub fn get_group_posts(
    request: GetGroupPostsRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetGroupPostsResponse, Status> {
    let post_id = request.post_id.to_db_id_or_err("post_id")?;
    let query = group_posts::table
        .inner_join(posts::table.on(group_posts::post_id.eq(posts::id)))
        // .left_join(memberships::table.on(memberships::group_id.eq(group_posts::group_id)))
        .select((
            group_posts::all_columns,
            posts::visibility,
            // memberships::all_columns.nullable(),
        ));
    let results: Vec<(models::GroupPost, String)> = match request.group_id {
         None => query
            .filter(group_posts::post_id.eq(post_id))
            .load::<(models::GroupPost, String)>(conn)
            .unwrap(),
        Some(group_id) => {
            let group_id = group_id.to_db_id_or_err("group_id")?;
            query
                .filter(group_posts::group_id.eq(group_id))
                .filter(group_posts::post_id.eq(post_id))
                .load::<(models::GroupPost, String)>(conn)
                .unwrap()
        }
    };
    let filtered_results = results
        .iter()
        .filter_map(|(group_post, post_visibility)| {
            let membership = models::get_membership(group_post.group_id, user.as_ref().map_or(-1, |u| u.id), conn).ok();
            let moderations = match (user.as_ref(), membership.as_ref()) {
                (Some(user), Some(membership)) => {
                    match (
                        membership.passes(),
                        validate_group_permission(&membership, &user, ModeratePosts),
                    ) {
                        (true, Ok(_)) => vec![Unmoderated, Approved, Pending],
                        _ => vec![Unmoderated, Approved],
                    }
                }
                _ => vec![Unmoderated, Approved],
            };
            match post_visibility.to_proto_visibility().unwrap() {
                Visibility::Limited => {
                    if !membership.as_ref().map(|m| m.passes()).unwrap_or(false) {
                        return None;
                    }
                }
                Visibility::GlobalPublic | Visibility::ServerPublic => {}
                Visibility::Unknown | Visibility::Private => return None,
                // _ => {}
            };
            if moderations.contains(&group_post.group_moderation.to_proto_moderation().unwrap()) {
                Some(group_post.to_proto())
            } else {
                None
            }
        })
        .collect::<Vec<GroupPost>>();

    Ok(GetGroupPostsResponse {
        group_posts: filtered_results,
    })
}
