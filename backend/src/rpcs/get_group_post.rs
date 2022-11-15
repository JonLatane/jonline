use diesel::*;
use tonic::{Code, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::models;
use crate::protos::Moderation::*;
use crate::protos::Permission::ModeratePosts;
use crate::protos::*;
use crate::schema::group_posts;

use super::validations::validate_group_permission;

pub fn get_group_post(
    request: GroupPost,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GroupPost, Status> {
    let group_id = request.to_owned().group_id.to_db_id_or_err("group_id")?;
    let post_id = request.to_owned().post_id.to_db_id_or_err("post_id")?;
    let group = models::get_group(group_id, conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;
    let membership = user
        .as_ref()
        .map(|u| models::get_membership(group_id, u.id, conn).ok())
        .flatten();
    let moderations = match (user.as_ref(), membership.as_ref()) {
        (Some(user), Some(membership)) => {
            match validate_group_permission(&membership, &user, ModeratePosts) {
                Ok(_) => vec![Unmoderated, Approved, Pending],
                Err(_) => vec![Unmoderated, Approved],
            }
        }
        _ => vec![Unmoderated, Approved],
    };

    // let moderations = vec![Moderation::Unmoderated, Moderation::Approved];
    let result = match group
        .default_membership_moderation
        .to_proto_moderation()
        .unwrap()
    {
        Moderation::Pending => {
            if !membership.map(|m| m.passes()).unwrap_or(false) {
                return Err(Status::new(Code::PermissionDenied, "not_a_member"));
            }
            load_group_post(group_id, post_id, moderations, conn)
        }
        _ => load_group_post(group_id, post_id, moderations, conn),
    }?;
    Ok(result.to_proto())
}

fn load_group_post(
    group_id: i32,
    post_id: i32,
    moderations: Vec<Moderation>,
    conn: &mut PgPooledConnection,
) -> Result<models::GroupPost, Status> {
    let result: Result<models::GroupPost, _> = group_posts::table
        .select(group_posts::all_columns)
        .filter(group_posts::group_id.eq(group_id))
        .filter(group_posts::post_id.eq(post_id))
        .filter(group_posts::group_moderation.eq_any(moderations.to_string_moderations()))
        .get_result::<models::GroupPost>(conn);

    result.map_err(|_| Status::new(Code::NotFound, "group_post_not_found"))
}
