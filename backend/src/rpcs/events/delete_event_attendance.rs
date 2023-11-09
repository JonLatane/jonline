use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::get_event_attendance;
use crate::protos::*;
use crate::schema::event_attendances;

pub fn delete_event_attendance(
    request: EventAttendance,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let event_instance_id = request
        .event_instance_id
        .to_db_id_or_err("event_instance_id")?;
    let user_id = user.map(|u| u.id);
    let anonymous_auth_token = request
        .attendee
        .map(|a| match a {
            event_attendance::Attendee::AnonymousAttendee(u) => u.auth_token,
            _ => None,
        })
        .flatten();
    let existing_attendance =
        get_event_attendance(event_instance_id, user_id, anonymous_auth_token, conn);

    match existing_attendance {
        Some(attendance) => diesel::delete(event_attendances::table)
            .filter(event_attendances::id.eq(attendance.id))
            .execute(conn)
            .map(|_| ())
            .map_err(|_e| Status::new(Code::Internal, "failed_to_delete_event_attendance")),
        None => Err(Status::new(Code::NotFound, "event_attendance_not_found")),
    }
}
