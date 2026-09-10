use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::posts;

use super::event_permissions::{event_post_id, find_existing_instance, validate_event_edit_permission};

/// Updates, in place, every `EventInstance` in `instances` that's already on the event (i.e.
/// whose `post.id` matches an existing instance belonging to this event). Any other instances are
/// ignored -- see `create_new_event_instances` for creating those instead.
///
/// An `EventInstance`'s identity *is* its `post.id`, so (unlike the old surrogate-ID scheme) a
/// matched instance's `post` is never missing here -- to explicitly reset an instance's Post to
/// `PRIVATE`, send its `post` with `visibility: PRIVATE` rather than omitting `post` entirely.
pub(super) fn update_event_instances_impl(
    event: &models::Event,
    instances: &[EventInstance],
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    for request_instance in instances {
        let Some(existing_instance) =
            find_existing_instance(request_instance, event.post_id, conn)
        else {
            continue;
        };
        let existing_instance_post = posts::table
            .select(models::POST_COLUMNS)
            .filter(posts::id.eq(existing_instance.post_id))
            .first::<models::Post>(conn)
            .map_err(|_| Status::new(Code::NotFound, "event_instance_post_not_found"))?;

        let mut updated_instance = existing_instance.clone();
        let starts_at = request_instance.starts_at.to_db()?;
        let ends_at = request_instance.ends_at.to_db()?;
        let location = request_instance
            .location
            .as_ref()
            .map(|c| serde_json::to_value(c).unwrap());
        if starts_at > ends_at {
            return Err(Status::new(
                Code::InvalidArgument,
                format!(
                    "instance[{}] starts_at must be before ends_at",
                    existing_instance.post_id
                ),
            ));
        }

        let timezone = request_instance.timezone.clone();

        if starts_at != updated_instance.starts_at
            || ends_at != updated_instance.ends_at
            || location != updated_instance.location
            || timezone != updated_instance.timezone
        {
            updated_instance.starts_at = starts_at;
            updated_instance.ends_at = ends_at;
            updated_instance.location = location;
            updated_instance.timezone = timezone;
            updated_instance.updated_at = SystemTime::now().into();
        }

        diesel::update(&updated_instance)
            .set(&updated_instance)
            .returning(models::EVENT_INSTANCE_COLUMNS)
            .get_result::<models::EventInstance>(conn)
            .map_err(|e| {
                log::error!("Failed to update event instance: {:?}", e);
                Status::new(Code::Internal, "failed_to_update_event_instance")
            })?;

        let mut updated_instance_post = existing_instance_post.clone();
        // `request_instance.post` is always `Some` here -- `find_existing_instance` can only
        // match via `post.id` -- so this `unwrap_or` is just a defensive fallback, not a live path.
        let visibility = request_instance
            .post
            .as_ref()
            .map(|p| p.visibility())
            .unwrap_or(Visibility::Private);
        if visibility.to_string_visibility() != updated_instance_post.visibility {
            updated_instance_post.visibility = visibility.to_string_visibility();
        }
        diesel::update(&updated_instance_post)
            .set(&updated_instance_post)
            .returning(models::POST_COLUMNS)
            .get_result::<models::Post>(conn)
            .map_err(|e| {
                log::error!("Failed to update event instance post: {:?}", e);
                Status::new(Code::Internal, "failed_to_update_event_instance")
            })?;
    }

    Ok(())
}

pub fn update_event_instances(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event_id = event_post_id(&request)?;
    let event = models::get_event(event_id, &Some(current_user), conn)?;
    validate_event_edit_permission(&event, current_user, conn)?;

    update_event_instances_impl(&event, &request.instances, conn)?;

    Ok(super::get_events(
        GetEventsRequest {
            post_id: Some(event_id.to_proto_id()),
            ..Default::default()
        },
        &Some(current_user),
        conn,
    )?
    .events[0]
        .clone())
}
