use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;

use super::create_new_event_instances::create_new_event_instances_impl;
use super::delete_removed_event_instances::delete_removed_event_instances_impl;
use super::event_permissions::validate_event_edit_permission;
use super::update_event_details::update_event_details_impl;
use super::update_event_instances::update_event_instances_impl;

/// Updates an Event, driving the same logic `UpdateEventDetails`, `CreateNewEventInstances`,
/// `UpdateEventInstances`, and `DeleteRemovedEventInstances` each expose standalone -- but calling
/// their shared `_impl` functions directly (rather than those RPCs themselves) so this runs as one
/// coherent operation instead of four independent ones:
/// - Create must run before Delete, so a request that both drops an old instance and adds a new
///   one never transiently leaves the event with zero instances (which `get_events`' `INNER JOIN`
///   can't represent -- see `deleting_the_only_instance_leaves_the_event_unretrievable_by_get_events`).
/// - Delete needs Create's *resolved* instances (ids filled in for newly-created entries), not the
///   original request -- otherwise a just-created instance (whose request entry has no id) looks
///   indistinguishable from an omitted one and gets deleted immediately after being created.
/// - Only one final `get_events` call, at the very end, builds the returned `Event`.
pub fn update_event(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event_id = request.id.to_db_id_or_err("id")?;
    update_event_details_impl(event_id, &request, current_user, conn)?;

    let event = models::get_event(event_id, &Some(current_user), conn)?;
    validate_event_edit_permission(&event, current_user, conn)?;
    let resolved_instances =
        create_new_event_instances_impl(&event, &request.instances, current_user, conn)?;
    update_event_instances_impl(&event, &request.instances, conn)?;
    delete_removed_event_instances_impl(&event, &resolved_instances, current_user, conn)?;

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
