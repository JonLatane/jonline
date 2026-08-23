use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::ToDbId;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_any_permission;
use crate::schema::posts;

/// Authorizes `current_user` to create/update/delete `EventInstance`s on `event`: either they own
/// the `Event`'s own `Post`, or they have `Admin`/`ModeratePosts`/`ModerateEvents` -- exactly
/// mirrors `update_post`'s `self_update`/`is_event_context` "moderator" check on the event's own
/// post, which is what implicitly gated this behavior back when it only lived inside
/// `update_event`/its private `update_event_instances` helper (that call ran first and short-
/// circuited the rest of `update_event` on failure).
pub(super) fn validate_event_edit_permission(
    event: &models::Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let event_post = posts::table
        .select(models::POST_COLUMNS)
        .filter(posts::id.eq(event.post_id))
        .first::<models::Post>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_post_not_found"))?;

    if event_post.user_id == Some(current_user.id) {
        return Ok(());
    }
    validate_any_permission(
        &Some(current_user),
        vec![
            Permission::Admin,
            Permission::ModeratePosts,
            Permission::ModerateEvents,
        ],
    )
}

/// Parses `id` and looks up an `EventInstance` belonging to `event_id`, or `None` if `id` doesn't
/// parse or belongs to a different (or no) event -- the same "not really this event's instance"
/// test `update_event.rs`'s original merge loop used to decide "treat this as a new instance".
pub(super) fn find_existing_instance(
    id: &String,
    event_id: i64,
    conn: &mut PgPooledConnection,
) -> Option<models::EventInstance> {
    use crate::schema::event_instances;

    let instance_id = id.to_db_id().ok()?;
    event_instances::table
        .select(models::EVENT_INSTANCE_COLUMNS)
        .filter(event_instances::id.eq(instance_id))
        .filter(event_instances::event_id.eq(event_id))
        .first::<models::EventInstance>(conn)
        .ok()
}
