use super::{Event, EventAttendance, EventInstance, Post, User};
use diesel::*;
use tonic::{Code, Status};

use crate::{
    db_connection::PgPooledConnection,
    schema::{event_attendances, event_instances, events, follows, posts, users},
};

pub fn get_event(
    event_id: i64,
    _user: &Option<User>,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    events::table
        .select(events::all_columns)
        .filter(events::id.eq(event_id))
        .first::<Event>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_not_found"))
}

pub fn get_event_instances(
    event_id: i64,
    user: &Option<User>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<(EventInstance, Option<Post>, Option<User>)>, Status> {
    event_instances::table
        .left_join(posts::table.on(event_instances::post_id.eq(posts::id.nullable())))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .left_join(
            follows::table.on(posts::user_id.eq(follows::target_user_id.nullable()).and(
                follows::user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id).unwrap_or(0)),
            )),
        )
        .select((
            event_instances::all_columns,
            posts::all_columns.nullable(),
            users::all_columns.nullable(),
        ))
        .filter(event_instances::event_id.eq(event_id))
        .load::<(EventInstance, Option<Post>, Option<User>)>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load event instances for event_id={}: {:?}",
                event_id,
                e
            );
            Status::new(Code::Internal, "failed_to_load_event_instances")
        })
}

pub fn get_event_attendances(
    event_instance_id: i64,
    user: &Option<User>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<EventAttendance>, Status> {
    event_attendances::table
        .inner_join(
            event_instances::table.on(event_attendances::event_instance_id.eq(event_instances::id)),
        )
        .left_join(posts::table.on(event_instances::post_id.eq(posts::id.nullable())))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .left_join(
            follows::table.on(posts::user_id.eq(follows::target_user_id.nullable()).and(
                follows::user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id).unwrap_or(0)),
            )),
        )
        .select(event_attendances::all_columns)
        .filter(event_attendances::event_instance_id.eq(event_instance_id))
        .load::<EventAttendance>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load event attendances for event_instance_id={}: {:?}",
                event_instance_id,
                e
            );
            Status::new(Code::Internal, "failed_to_load_event_attendances")
        })
}

// pub fn get_group_event(group_id: i64, event_id: i64, conn: &mut PgPooledConnection,) -> Result<GroupEvent, Status> {
//     group_posts::table
//         .select(group_posts::all_columns)
//         .filter(group_posts::group_id.eq(group_id))
//         .filter(group_posts::event_id.eq(event_id))
//         .first::<GroupEvent>(conn)
//         .map_err(|_| Status::new(Code::NotFound, "group_event_not_found"))
// }
