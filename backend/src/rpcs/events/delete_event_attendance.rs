use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::get_event_attendance;
use crate::protos::*;
use crate::schema::{event_attendances, event_instances, events, posts};

pub fn delete_event_attendance(
    request: EventAttendance,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let event_instance_id = request
        .event_instance_id
        .to_db_id_or_err("event_instance_id")?;

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
        // .execute(conn)
        .map_err(|_e| Status::new(Code::Internal, "invalid_event_instance_id"))?;

    let is_event_owner = user.is_some() && event_post.user_id == user.map(|u| u.id);
    let is_own_attendance = match &request.attendee {
        Some(event_attendance::Attendee::UserAttendee(author)) => {
            user.is_some() && user.map(|u| u.id) == author.user_id.to_db_id().ok()
        }
        _ => false,
    };

    let attendee_user_id = match &request.attendee {
        Some(event_attendance::Attendee::UserAttendee(author)) => {
            Some(author.user_id.to_db_id_or_err("author.user_id")?)
        }
        _ => None,
    };
    let is_anonymous = attendee_user_id.is_none();

    let attendee_user_id = match &request.attendee {
        Some(event_attendance::Attendee::UserAttendee(attendee)) => {
            Some(attendee.user_id.to_db_id_or_err("user_id")?)
        }
        _ => None,
    };
    // let is_anonymous = attendee_user_id.is_none();

    if !is_event_owner && !is_own_attendance && !is_anonymous {
        return Err(Status::new(
            Code::PermissionDenied,
            "not_your_event_or_attendance",
        ));
    }

    let attendee_auth_token = request
        .attendee
        .as_ref()
        .map(|a| match a {
            event_attendance::Attendee::AnonymousAttendee(u) => u.auth_token.clone(),
            _ => None,
        })
        .flatten();
    let existing_attendance = get_event_attendance(
        event_instance_id,
        attendee_user_id,
        attendee_auth_token,
        conn,
    );

    match existing_attendance {
        Some(attendance) => diesel::delete(event_attendances::table)
            .filter(event_attendances::id.eq(attendance.0.id))
            .execute(conn)
            .map(|_| ())
            .map_err(|_e| Status::new(Code::Internal, "failed_to_delete_event_attendance")),
        None => Err(Status::new(Code::NotFound, "event_attendance_not_found")),
    }
}
