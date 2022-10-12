use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::follows;

pub fn update_follow(
    request: Follow,
    current_user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Follow, Status> {
    validate_follow(&request, OperationType::Update)?;
    if request.target_user_id != current_user.id.to_proto_id() {
        return Err(Status::new(
            Code::InvalidArgument,
            "only_target_user_can_update_follow",
        ));
    }
    let mut existing_follow = follows::table
        .select(follows::all_columns)
        .filter(follows::user_id.eq(request.user_id.to_db_id().unwrap()))
        .filter(follows::target_user_id.eq(request.target_user_id.to_db_id().unwrap()))
        .first::<models::Follow>(conn)
        .map_err(|_| Status::new(Code::NotFound, "follow_not_found"))?;

    existing_follow.target_user_moderation = request.target_user_moderation.to_string_moderation();

    existing_follow.updated_at = SystemTime::now().into();

    match diesel::update(follows::table)
        .filter(follows::user_id.eq(request.user_id.to_db_id().unwrap()))
        .filter(follows::target_user_id.eq(request.target_user_id.to_db_id().unwrap()))
        .set(&existing_follow)
        .execute(conn)
    {
        Ok(_) => {
            existing_follow.update_related_counts(conn)?;
            Ok(existing_follow.to_proto())
        }
        Err(e) => {
            println!("Error updating follow: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating_follow"))
        }
    }
}
