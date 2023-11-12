use diesel::*;

use ring::rand::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::generate_token;
use crate::marshaling::*;
use crate::models;
use crate::models::{get_event_attendance, NewEventAttendance};
use crate::protos::*;
use crate::schema::{event_attendances, event_instances, events, posts};

pub fn upsert_event_attendance(
    request: EventAttendance,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<EventAttendance, Status> {
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
        Some(event_attendance::Attendee::UserId(user_id)) => {
            user.is_some() && user.map(|u| u.id) == user_id.to_db_id().ok()
        }
        _ => false,
    };

    let attendee_user_id = match &request.attendee {
        Some(event_attendance::Attendee::UserId(user_id)) => {
            Some(user_id.to_db_id_or_err("user_id")?)
        }
        _ => None,
    };
    let is_anonymous = attendee_user_id.is_none();

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
    let anonymous_attendee: Option<AnonymousAttendee> = match &attendee_user_id {
        Some(_user_id) => None,
        None => match request.attendee {
            Some(event_attendance::Attendee::AnonymousAttendee(attendee)) => {
                Some(AnonymousAttendee {
                    name: attendee.name,
                    contact_methods: attendee.contact_methods,
                    auth_token: Some(generate_token!(128)),
                })
            }
            Some(event_attendance::Attendee::UserId(_)) => None,
            None => return Err(Status::new(Code::InvalidArgument, "attendee_required")),
        },
    };

    //TODO Validate moderation changes, etc.

    match existing_attendance {
        Some(mut attendance) => {
            if !is_own_attendance && !is_event_owner {
                return Err(Status::new(
                    Code::PermissionDenied,
                    "cannot_update_attendance",
                ));
            }
            if is_anonymous
                && anonymous_attendee.is_some()
                && (&anonymous_attendee.unwrap().name
                    != &attendance
                        .anonymous_attendee
                        .as_ref()
                        .unwrap()
                        .get("name")
                        .unwrap()
                        .as_str()
                        .unwrap()
                        .to_string()
                        || &attendance.public_note != &request.public_note)
            {
                attendance.moderation = Moderation::Pending.to_string_moderation();
            }
            if is_own_attendance {
                attendance.number_of_guests = i32::try_from(request.number_of_guests)
                    .map_err(|_e| Status::new(Code::InvalidArgument, "invalid_number_of_guests"))?;
            }

            diesel::update(event_attendances::table)
                .filter(event_attendances::id.eq(attendance.id))
                .set(attendance.clone())
                .execute(conn)
                .map_err(|_e| Status::new(Code::Internal, "failed_to_update_event_attendance"))?;

            Ok(attendance.to_proto(true, true))
        }
        None => {
            let authenticated_user_id = &user.map(|u| u.id);
            let inviting_user_id = match (authenticated_user_id, &attendee_user_id) {
                (Some(a), Some(b)) if b == a => user.map(|u| u.id),
                _ => None,
            };
            let status = match (
                inviting_user_id,
                request.status.to_proto_attendance_status(),
            ) {
                (Some(_), _) => AttendanceStatus::Requested.to_string_attendance_status(),
                _ => AttendanceStatus::Interested.to_string_attendance_status(),
            };
            let attendance = diesel::insert_into(event_attendances::table)
                .values(NewEventAttendance {
                    event_instance_id,
                    user_id: attendee_user_id,
                    inviting_user_id,
                    status,
                    anonymous_attendee: anonymous_attendee
                        .map(|a| serde_json::to_value(a).unwrap()),
                    number_of_guests: i32::try_from(request.number_of_guests).map_err(|_e| {
                        Status::new(Code::InvalidArgument, "invalid_number_of_guests")
                    })?,
                    public_note: request.public_note,
                    private_note: request.private_note,
                })
                .get_result::<models::EventAttendance>(conn)
                .map_err(|_e| Status::new(Code::Internal, "failed_to_create_event_attendance"))?;
            Ok(attendance.to_proto(true, true))
        }
    }
}
