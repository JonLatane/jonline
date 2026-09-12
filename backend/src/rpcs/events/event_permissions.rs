use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::ToDbId;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_any_permission;
use crate::schema::posts;

/// Extracts the DB ID an `Event` request identifies itself by -- its `post.id` (an `Event`'s
/// identity *is* its own Post's ID -- there's no separate surrogate ID) -- for the handful of RPCs
/// (`UpdateEvent`, `UpdateOccasions`, `CreateNewOccasions`, `DeleteRemovedOccasions`,
/// `DeleteEvent`) that take a full `Event` just to say "this one" plus a payload.
pub(super) fn event_post_id(request: &Event) -> Result<i64, Status> {
    request
        .post
        .as_ref()
        .ok_or_else(|| Status::new(Code::InvalidArgument, "post_required"))?
        .id
        .to_db_id_or_err("post.id")
}

/// Authorizes `current_user` to create/update/delete `Occasion`s on `event`: either they own
/// the `Event`'s own `Post`, or they have `Admin`/`ModeratePosts`/`ModerateEvents` -- exactly
/// mirrors `update_post`'s `self_update`/`is_event_context` "moderator" check on the event's own
/// post, which is what implicitly gated this behavior back when it only lived inside
/// `update_event`/its private `update_occasions` helper (that call ran first and short-
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

/// Looks up an `Occasion` belonging to `event_id` by `instance.post.id` (an `Occasion`'s
/// identity *is* its own Post's ID -- there's no separate surrogate ID), or `None` if `instance`
/// has no `post`, `post.id` doesn't parse, or it belongs to a different (or no) event -- the same
/// "not really this event's instance" test `update_event.rs`'s original merge loop used to decide
/// "treat this as a new instance". A `None` `post` can therefore never match an existing instance:
/// unlike the old surrogate-ID scheme, there's no way to identify *which* instance to update
/// without including its Post (see `update_occasions_impl`'s doc for what that means for
/// resetting an instance's Post to `PRIVATE`).
pub(super) fn find_existing_instance(
    instance: &Occasion,
    event_id: i64,
    conn: &mut PgPooledConnection,
) -> Option<models::Occasion> {
    use crate::schema::occasions;

    let instance_post_id = instance.post.as_ref()?.id.to_db_id().ok()?;
    occasions::table
        .select(models::OCCASION_COLUMNS)
        .filter(occasions::post_id.eq(instance_post_id))
        .filter(occasions::event_id.eq(event_id))
        .first::<models::Occasion>(conn)
        .ok()
}
