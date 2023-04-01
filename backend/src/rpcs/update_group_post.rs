use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::models::{get_group_post, get_membership};
use crate::protos::*;
use crate::schema::group_posts;

pub fn update_group_post(
    request: GroupPost,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<GroupPost, Status> {
    // validate_group_user_moderator(&request, OperationType::Update)?;

    let group_id = request.group_id.to_db_id_or_err("group_id")?;
    let post_id = request.post_id.to_db_id_or_err("post_id")?;
    let membership = get_membership(group_id, current_user.id, conn)?;
    validate_group_permission(&membership, &current_user, Permission::ModeratePosts)?;

    let mut existing_group_post = get_group_post(group_id, post_id, conn)?;
    existing_group_post.group_moderation = request.group_moderation.to_string_moderation();
    existing_group_post.updated_at = SystemTime::now().into();

    match diesel::update(group_posts::table)
    .filter(group_posts::group_id.eq(request.group_id.to_db_id().unwrap()))
    .filter(group_posts::post_id.eq(request.post_id.to_db_id().unwrap()))
        .set(&existing_group_post)
        .execute(conn)
    {
        Ok(_) => {
            existing_group_post.update_related_counts(conn)?;
            Ok(existing_group_post.to_proto())
        }
        Err(e) => {
            log::error!("Error updating group_post: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating_group_post"))
        }
    }
}
