use diesel::*;
use tonic::{Code, Status};

use crate::{
    db_connection::PgPooledConnection,
    models::{self, get_event},
    protos::*,
    rpcs::validate_permission,
    schema::{events, posts},
};

use super::event_permissions::event_post_id;

pub fn delete_event(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let admin = validate_permission(&Some(current_user), Permission::Admin).is_ok();
    // let moderator = validate_permission(&Some(current_user), Permission::ModerateEvents).is_ok();

    let event = get_event(event_post_id(&request)?, &Some(current_user), conn)?;
    let event_post = posts::table
        .select(models::POST_COLUMNS)
        .filter(posts::id.eq(event.post_id))
        .first::<models::Post>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_post_not_found"))?;

    if event_post.user_id != Some(current_user.id) && !admin {
        return Err(Status::new(Code::PermissionDenied, "permission_denied"));
    }

    // Captured before the delete -- refresh the actual owner's counts, not necessarily
    // `current_user` (an admin can delete another user's event).
    let event_owner_id = event_post.user_id;

    let transaction_result: Result<(), diesel::result::Error> = conn
        .transaction::<(), diesel::result::Error, _>(|conn| {
            diesel::delete(events::table)
                .filter(events::post_id.eq(event.post_id))
                .execute(conn)?;

            if let Some(owner_id) = event_owner_id {
                crate::logic::update_event_counts(owner_id, conn)?;
            }
            Ok(())
        });

    if transaction_result.is_err() {
        return Err(Status::new(Code::Internal, "error_during_delete"));
    }

    Ok(request)
}
