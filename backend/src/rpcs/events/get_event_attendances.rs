use diesel::*;
// use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::{event_attendances, event_instances, events, posts};

use crate::rpcs::validations::*;

pub fn get_event_attendances(
    request: GetEventAttendancesRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<EventAttendances, Status> {
    let event_instance_id = request.event_instance_id.to_db_id_or_err("id")?;

    let (_event, event_post, _event_instance): (
        models::Event,
        models::Post,
        models::EventInstance,
    ) = event_instances::table
        .inner_join(events::table.on(event_instances::event_id.eq(events::id)))
        .inner_join(posts::table.on(events::post_id.eq(posts::id)))
        .filter(event_instances::id.eq(event_instance_id))
        .select((
            events::all_columns,
            posts::all_columns,
            event_instances::all_columns,
        ))
        .first::<(models::Event, models::Post, models::EventInstance)>(conn)
        .map_err(|_e| Status::new(Code::Internal, "invalid_event_instance_id"))?;

    let is_event_owner = user.is_some() && event_post.user_id == user.map(|u| u.id);

    match (event_post.visibility.to_proto_visibility().unwrap(), user) {
        (Visibility::GlobalPublic, _) => {}
        (Visibility::ServerPublic, Some(user)) => {
            validate_permission(user, Permission::ViewEvents)?
        }
        (Visibility::ServerPublic, None) => {
            return Err(Status::new(
                Code::PermissionDenied,
                "not_logged_in_cannot_view_local_events",
            ))
        }
        (Visibility::Limited, Some(user))
            if event_post.user_id.map(|id| id == user.id).unwrap_or(false) => {}
        (Visibility::Private, Some(user))
            if event_post.user_id.map(|id| id == user.id).unwrap_or(false) => {}
        _ => {
            return Err(Status::new(
                Code::PermissionDenied,
                "not_logged_in_cannot_view_private_events",
            ))
        }
    }

    let mut event_attendances_query = event_attendances::table
        .filter(event_attendances::event_instance_id.eq(event_instance_id))
        .into_boxed();

    if !is_event_owner {
        event_attendances_query = event_attendances_query
            .filter(event_attendances::moderation.eq_any(PASSING_MODERATIONS));
    }

    let attendances: Vec<models::EventAttendance> = event_attendances_query
        .load::<models::EventAttendance>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load event attendances for event_instance_id={}: {:?}",
                event_instance_id,
                e
            );
            Status::new(Code::Internal, "failed_to_load_event_attendances")
        })?;

    Ok(EventAttendances {
        attendances: attendances
            .into_iter()
            .map(|a| {
                let include_private_note = is_event_owner
                    || (a.user_id.is_some()
                        && user.is_some()
                        && a.user_id.unwrap() == user.unwrap().id)
                    || (request.anonymous_attendee_auth_token.is_some()
                        && a.anonymous_attendee.is_some()
                        && match a.to_proto(true, false).attendee.unwrap() {
                            event_attendance::Attendee::AnonymousAttendee(anonymous_attendee) => {
                                anonymous_attendee.auth_token.unwrap()
                                    == request
                                        .anonymous_attendee_auth_token
                                        .as_ref()
                                        .unwrap()
                                        .clone()
                            }
                            _ => false,
                        });
                a.to_proto(include_private_note, include_private_note)
            })
            .collect(),
    })
}
