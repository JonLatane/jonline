use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::posts;

use super::event_permissions::{find_existing_instance, validate_event_edit_permission};

/// Updates, in place, every `EventInstance` in `instances` that's already on the event (i.e.
/// whose `id` matches an existing instance belonging to this event). Any other instances are
/// ignored -- see `create_new_event_instances` for creating those instead.
///
/// A matched instance with no `post` has its Post's visibility reset to `PRIVATE` -- a missing
/// `post` is treated as an explicit `Visibility::Private`, not "leave the current visibility
/// alone" (mirrors `update_event.rs`'s original behavior).
pub(super) fn update_event_instances_impl(
    event: &models::Event,
    instances: &[EventInstance],
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    for request_instance in instances {
        let Some(existing_instance) = find_existing_instance(&request_instance.id, event.id, conn)
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
                    existing_instance.id
                ),
            ));
        }

        if starts_at != updated_instance.starts_at
            || ends_at != updated_instance.ends_at
            || location != updated_instance.location
        {
            updated_instance.starts_at = starts_at;
            updated_instance.ends_at = ends_at;
            updated_instance.location = location;
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
    let event_id = request.id.to_db_id_or_err("id")?;
    let event = models::get_event(event_id, &Some(current_user), conn)?;
    validate_event_edit_permission(&event, current_user, conn)?;

    update_event_instances_impl(&event, &request.instances, conn)?;

    Ok(super::get_events(
        GetEventsRequest {
            event_id: Some(event_id.to_proto_id()),
            ..Default::default()
        },
        &Some(current_user),
        conn,
    )?
    .events[0]
        .clone())
}
