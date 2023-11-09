use diesel::*;
use tonic::{Code, Status};

use crate::rpcs::validations::*;
use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::group_posts;

pub fn create_group_post(
    request: GroupPost,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<GroupPost, Status> {
    let group_id = request.group_id.to_db_id_or_err("group_id")?;
    let membership = models::get_membership(group_id, user.id, conn)?;
    validate_group_permission(&membership, &user, Permission::CreatePosts)?;

    let post_id = request.post_id.to_db_id_or_err("post_id")?;
    let post = models::get_post(post_id, conn)?;
    if post.visibility.to_proto_visibility() == Some(Visibility::Direct) {
        return Err(Status::new(
            Code::InvalidArgument,
            "Direct posts may not be added to groups",
        ));
    }

    let group = models::get_group(group_id, conn)?;
    let group_post_result: Result<models::GroupPost, diesel::result::Error> =
        conn.transaction::<models::GroupPost, diesel::result::Error, _>(|conn| {
            let group_post = insert_into(group_posts::table)
                .values(&models::NewGroupPost {
                    post_id: post_id,
                    group_id: group_id,
                    user_id: user.id,
                    group_moderation: group.default_post_moderation,
                    // target_user_id: request.target_user_id.to_db_id().unwrap(),
                    // target_user_moderation: target_user.default_group_post_moderation,
                })
                .get_result::<models::GroupPost>(conn)?;
            Ok(group_post)
        });
    let group_post = group_post_result.map_err(|e| {
        log::error!("Error creating group post! {:?}", e);
        Status::new(Code::Internal, "data_error")
    })?;
    group_post.update_related_counts(conn)?;
    Ok(group_post.to_proto())
}
