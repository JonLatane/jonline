use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::get_group_and_membership;
use crate::protos::*;
use crate::rpcs::validations::*;
use crate::schema::{event_instances, events, group_posts};

pub fn delete_group_post(
    request: GroupPost,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let group_id = request.group_id.to_db_id_or_err("group_id")?;
    let post_id = request.post_id.to_db_id_or_err("post_id")?;

    let existing_group_post = group_posts::table
        .select(group_posts::all_columns)
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::post_id.eq(post_id))
        .first::<models::GroupPost>(conn)
        .map_err(|_| Status::new(Code::NotFound, "group_post_not_found"))?;
    // let membership = get_membership(group_id, current_user.id, conn)?;
    let (group, membership) = get_group_and_membership(group_id, Some(current_user.id), conn)?;
    if existing_group_post.user_id != current_user.id {
        validate_group_permission(
            &group,
            &membership.as_ref(),
            &Some(current_user),
            Permission::Admin,
        )?;
    }

    let post = models::get_post(post_id, conn)?;
    // Delete all EventInstance GroupPosts if the Event is no longer visible to the Group.
    if post.context.to_proto_post_context().unwrap() == PostContext::Event
        && post.visibility.to_proto_visibility().unwrap() == Visibility::Limited
    {
        let instance_post_ids = events::table
            .inner_join(event_instances::table.on(events::id.eq(event_instances::event_id)))
            .filter(events::post_id.eq(post_id))
            .filter(event_instances::post_id.is_not_null())
            .select(event_instances::post_id.assume_not_null())
            .load::<i64>(conn)
            .map_err(|_| Status::new(Code::Internal, "error_cleaning_up_instance_group_posts"))?;

        diesel::delete(group_posts::table)
            .filter(group_posts::group_id.eq(group_id))
            .filter(group_posts::post_id.eq_any(instance_post_ids))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_cleaning_up_instance_group_posts"))?;
    }

    match diesel::delete(group_posts::table)
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::post_id.eq(post_id))
        .execute(conn)
    {
        Ok(_) => {
            existing_group_post.update_related_counts(conn)?;
            Ok(())
        }
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
