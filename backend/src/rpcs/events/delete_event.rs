use diesel::*;
use tonic::{Code, Status};

use crate::{
    db_connection::PgPooledConnection,
    marshaling::ToDbId,
    models::{self, get_event},
    protos::*,
    rpcs::validate_permission,
    schema::{events, posts, users},
};

pub fn delete_event(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let admin = validate_permission(&Some(current_user), Permission::Admin).is_ok();
    // let moderator = validate_permission(&Some(current_user), Permission::ModerateEvents).is_ok();

    let event = get_event(request.id.to_db_id_or_err("id")?, &Some(current_user), conn)?;
    let event_post = posts::table
        .select(posts::all_columns)
        .filter(posts::id.eq(event.post_id))
        .first::<models::Post>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_post_not_found"))?;

    if event_post.user_id != Some(current_user.id) && !admin {
        return Err(Status::new(Code::PermissionDenied, "permission_denied"));
    }

    let transaction_result: Result<(), diesel::result::Error> = conn
        .transaction::<(), diesel::result::Error, _>(|conn| {
            let deleted_count = diesel::delete(events::table)
                .filter(events::id.eq(event.id))
                .execute(conn)? as i32;

            update(users::table)
                .filter(users::id.eq(current_user.id))
                .set(users::event_count.eq(users::event_count - deleted_count))
                .execute(conn)?;
            Ok(())
        });

    if transaction_result.is_err() {
        return Err(Status::new(Code::Internal, "error_during_delete"));
    }

    Ok(request)
}
