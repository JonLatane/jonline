use diesel::*;
use tonic::{Code, Status};

use super::validations::*;
use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{follows, users};

pub fn create_follow(
    request: Follow,
    user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Follow, Status> {
    validate_follow(&request, OperationType::Create)?;
    if request.user_id != user.id.to_proto_id() {
        validate_permission(&user, Permission::Admin)?;
    }
    let target_user = users::table
        .select(users::all_columns)
        .filter(users::id.eq(request.target_user_id.to_db_id_or_err("target_user_id")?))
        .first::<models::User>(conn)
        .map_err(|_| Status::new(Code::NotFound, "target_user_not_found"))?;

    let follow_result: Result<models::Follow, diesel::result::Error> = conn
        .transaction::<models::Follow, diesel::result::Error, _>(|conn| {
            let follow = insert_into(follows::table)
                .values(&models::NewFollow {
                    user_id: user.id,
                    target_user_id: request.target_user_id.to_db_id().unwrap(),
                    target_user_moderation: target_user.default_follow_moderation,
                })
                .get_result::<models::Follow>(conn)?;
            Ok(follow)
        });
    let follow = follow_result.map_err(|e| {
        log::error!("Error creating follow! {:?}", e);
        Status::new(Code::Internal, "data_error")
    })?;
    follow.update_related_counts(conn)?;
    Ok(follow.to_proto())
}
