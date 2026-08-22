use std::collections::HashSet;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::event_instances;

use super::event_permissions::validate_event_edit_permission;

/// Deletes every `EventInstance` currently on the event whose `id` isn't present in `instances`
/// -- their own `Post`s are left behind, not cascade-deleted. Refreshes `event_instance_count` for
/// `current_user` and for any other user who owned a deleted instance's Post (e.g. an admin
/// deleting instances on someone else's event).
///
/// Callers orchestrating this alongside `create_new_event_instances` (like `update_event`) must
/// pass `instances` with any newly-created entries' ids already resolved (that function's return
/// value) -- an id-less entry here can't be matched to anything, so it wouldn't protect a
/// just-created instance from being swept up as "not present in `instances`".
pub(super) fn delete_removed_event_instances_impl(
    event: &models::Event,
    instances: &[EventInstance],
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let existing_instance_data = models::get_event_instances(event.id, &Some(current_user), conn)?;
    let kept_ids: HashSet<i64> = instances
        .iter()
        .filter_map(|i| i.id.to_db_id().ok())
        .collect();

    let removed_instance_ids: Vec<i64> = existing_instance_data
        .iter()
        .filter(|(instance, _, _)| !kept_ids.contains(&instance.id))
        .map(|(instance, _, _)| instance.id)
        .collect();
    // Instances owned by users other than `current_user` (e.g. an admin editing someone else's
    // event) that are about to be deleted -- their `event_instance_count` needs refreshing too.
    let removed_instance_owner_ids: Vec<i64> = existing_instance_data
        .iter()
        .filter(|(instance, _, _)| removed_instance_ids.contains(&instance.id))
        .filter_map(|(_, post, _)| post.user_id)
        .collect();

    diesel::delete(event_instances::table.filter(event_instances::id.eq_any(removed_instance_ids)))
        .execute(conn)
        .map_err(|e| {
            log::error!("Failed to delete event instances: {:?}", e);
            Status::new(Code::Internal, "failed_to_delete_event_instances")
        })?;

    let mut affected_user_ids = removed_instance_owner_ids;
    affected_user_ids.push(current_user.id);
    affected_user_ids.sort_unstable();
    affected_user_ids.dedup();
    for user_id in affected_user_ids {
        crate::logic::update_event_counts(user_id, conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_event_counts"))?;
    }

    Ok(())
}

pub fn delete_removed_event_instances(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event_id = request.id.to_db_id_or_err("id")?;
    let event = models::get_event(event_id, &Some(current_user), conn)?;
    validate_event_edit_permission(&event, current_user, conn)?;

    delete_removed_event_instances_impl(&event, &request.instances, current_user, conn)?;

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
