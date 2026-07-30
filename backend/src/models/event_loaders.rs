use super::{
    Author, Event, EventAttendance, EventInstance, EventSyncSource, Post, User, AUTHOR_COLUMNS,
    EVENT_INSTANCE_COLUMNS, POST_COLUMNS,
};
use diesel::{
    dsl::sql,
    sql_types::{Bool, Text},
    *,
};
use tonic::{Code, Status};

use crate::{
    db_connection::PgPooledConnection,
    // protos::Author,
    schema::{event_attendances, event_instances, event_sync_sources, events, follows, posts, users},
};

pub fn get_event_sync_source(
    id: i64,
    conn: &mut PgPooledConnection,
) -> Result<EventSyncSource, Status> {
    event_sync_sources::table
        .select(event_sync_sources::all_columns)
        .filter(event_sync_sources::id.eq(id))
        .first::<EventSyncSource>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_sync_source_not_found"))
}

pub fn get_event_sync_sources_for_user(
    user_id: i64,
    conn: &mut PgPooledConnection,
) -> Result<Vec<(EventSyncSource, Author)>, Status> {
    event_sync_sources::table
        .inner_join(users::table.on(event_sync_sources::user_id.eq(users::id)))
        .select((event_sync_sources::all_columns, AUTHOR_COLUMNS))
        .filter(event_sync_sources::user_id.eq(user_id))
        .order(event_sync_sources::created_at.desc())
        .load::<(EventSyncSource, Author)>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load event sync sources for user_id={}: {:?}",
                user_id,
                e
            );
            Status::new(Code::Internal, "failed_to_load_event_sync_sources")
        })
}

pub fn get_event_sync_sources_by_ids(
    ids: Vec<i64>,
    conn: &mut PgPooledConnection,
) -> Vec<(EventSyncSource, Author)> {
    if ids.is_empty() {
        return vec![];
    }
    event_sync_sources::table
        .inner_join(users::table.on(event_sync_sources::user_id.eq(users::id)))
        .select((event_sync_sources::all_columns, AUTHOR_COLUMNS))
        .filter(event_sync_sources::id.eq_any(ids))
        .load::<(EventSyncSource, Author)>(conn)
        .unwrap_or_default()
}

pub fn get_event(
    event_id: i64,
    _user: &Option<&User>,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    events::table
        .select(events::all_columns)
        .filter(events::id.eq(event_id))
        .first::<Event>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_not_found"))
}

pub fn get_event_instance(
    event_instance_id: i64,
    _user: &Option<&User>,
    conn: &mut PgPooledConnection,
) -> Result<EventInstance, Status> {
    event_instances::table
        .select(EVENT_INSTANCE_COLUMNS)
        .filter(event_instances::id.eq(event_instance_id))
        .first::<EventInstance>(conn)
        .map_err(|_| Status::new(Code::NotFound, "event_instance_not_found"))
}

pub fn get_event_instances(
    event_id: i64,
    user: &Option<&User>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<(EventInstance, Post, Option<Author>)>, Status> {
    event_instances::table
        .inner_join(posts::table.on(event_instances::post_id.eq(posts::id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .left_join(
            follows::table.on(posts::user_id.eq(follows::target_user_id.nullable()).and(
                follows::user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id).unwrap_or(0)),
            )),
        )
        .select((
            EVENT_INSTANCE_COLUMNS,
            POST_COLUMNS,
            AUTHOR_COLUMNS.nullable(),
        ))
        .filter(event_instances::event_id.eq(event_id))
        .load::<(EventInstance, Post, Option<Author>)>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load event instances for event_id={}: {:?}",
                event_id,
                e
            );
            Status::new(Code::Internal, "failed_to_load_event_instances")
        })
}

// Gets an existing event attendance for update/deletion.
pub fn get_event_attendance(
    event_instance_id: i64,
    attendee_user_id: Option<i64>,
    attendee_auth_token: Option<String>,
    conn: &mut PgPooledConnection,
) -> Option<(EventAttendance, Option<Author>)> {
    match (attendee_user_id, attendee_auth_token) {
        (Some(user_id), _) => event_attendances::table
            .left_join(users::table.on(event_attendances::user_id.eq(users::id.nullable())))
            .select((event_attendances::all_columns, AUTHOR_COLUMNS.nullable()))
            .filter(event_attendances::event_instance_id.eq(event_instance_id))
            .filter(event_attendances::user_id.eq(Some(user_id)))
            .get_result::<(EventAttendance, Option<Author>)>(conn)
            .ok(),
        (_, Some(auth_token)) => event_attendances::table
            .left_join(users::table.on(event_attendances::user_id.eq(users::id.nullable())))
            .select((event_attendances::all_columns, AUTHOR_COLUMNS.nullable()))
            .filter(event_attendances::event_instance_id.eq(event_instance_id))
            .filter(event_attendances::anonymous_attendee.is_not_null().and(
                sql::<Bool>("anonymous_attendee->>'auth_token' = ").bind::<Text, _>(auth_token),
            ))
            .get_result::<(EventAttendance, Option<Author>)>(conn)
            .ok(),
        (_, _) => None,
    }
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
        .left_join(posts::table.on(event_instances::post_id.eq(posts::id)))
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
