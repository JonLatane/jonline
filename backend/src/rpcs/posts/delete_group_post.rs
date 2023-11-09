use diesel::*;
use tonic::{Code, Status};

use crate::rpcs::validations::*;
use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::models::get_membership;
use crate::protos::*;
use crate::schema::group_posts;

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
    let membership = get_membership(group_id, current_user.id, conn)?;
    if existing_group_post.user_id != current_user.id {
        validate_group_permission(&membership, &current_user, Permission::Admin)?;
    }

    match diesel::delete(group_posts::table)
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::post_id.eq(post_id))
        .execute(conn)
    {
        Ok(_) => {
            existing_group_post.update_related_counts(conn)?;
            Ok(())
        },
        Err(_) => Err(Status::new(Code::Internal, "data_error")),
    }
}
