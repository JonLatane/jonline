use std::time::SystemTime;

use diesel::*;
use log::info;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::marshaling::*;
use crate::models;
use crate::models::AUTHOR_COLUMNS;
use crate::protos::*;
use crate::rpcs::validate_group_permission;
use crate::schema::*;

type EventLoadData = (
    models::EventInstance,
    models::Event,
    models::Post,
    Option<models::Author>,
    Option<models::Post>,
    Option<models::Author>,
);
pub fn get_events(
    request: GetEventsRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetEventsResponse, Status> {
    let result: Vec<MarshalableEvent> = match (
        request.listing_type(),
        request.to_owned().event_id,
        request.to_owned().event_instance_id,
        request.to_owned().author_user_id,
    ) {
        // TODO: implement the other listing types
        (_, Some(event_id), _, _) => get_event_by_id(&user, &event_id, conn)?,
        (_, _, Some(instance_id), _) => get_event_by_instance_id(&user, &instance_id, conn)?,
        (EventListingType::GroupEvents, _, _, _) => match request.group_id {
            Some(group_id) => get_group_events(
                group_id.to_db_id_or_err("group_id")?,
                &user,
                conn,
                request.time_filter,
            )?,
            _ => return Err(Status::new(Code::InvalidArgument, "group_id_invalid")),
        },
        (_, _, _, Some(author_user_id)) => get_user_events(
            author_user_id.to_db_id_or_err("author_user_id")?,
            user,
            conn,
            request.time_filter,
        )?,
        _ => get_public_and_following_events(&user, conn, request.time_filter)?,
    };
    Ok(GetEventsResponse {
        events: convert_events(&result, conn),
    })
}

macro_rules! visible_to_current_user {
    ($user:expr, $instance_posts:expr, $instance_users:expr) => {{
        posts::visibility
            .eq_any(public_string_visibilities($user))
            .or(posts::visibility
                .eq(Visibility::Limited.to_string_visibility())
                .and(follows::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
            // .or(posts::visibility
            //     .eq(Visibility::Private.to_string_visibility())
            //     .and(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
            .or(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0)))
    }};
}

macro_rules! select_events_instancewise {
    ($user:expr, $timefilter:expr) => {{
        let ends_after = $timefilter
            .map(|f| f.ends_after.map(|t| t.to_db()))
            .flatten()
            .unwrap_or(SystemTime::now());
        println!("ends_after={:?}", ends_after);

        let instance_posts = alias!(posts as instance_posts);
        let instance_users = alias!(users as instance_users);

        event_instances::table
            .inner_join(events::table.on(events::id.eq(event_instances::event_id)))
            .inner_join(posts::table.on(posts::id.eq(events::post_id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .left_join(
                follows::table.on(posts::user_id.eq(follows::target_user_id.nullable()).and(
                    follows::user_id
                        .nullable()
                        .eq($user.as_ref().map(|u| u.id).unwrap_or(0)),
                )),
            )
            .left_join(
                instance_posts
                    .on(event_instances::post_id.eq(instance_posts.field(posts::id).nullable())),
            )
            .left_join(
                instance_users.on(instance_posts
                    .field(posts::user_id)
                    .eq(instance_users.field(users::id).nullable())),
            )
            .select((
                event_instances::all_columns,
                events::all_columns,
                posts::all_columns,
                AUTHOR_COLUMNS.nullable(),
                instance_posts.fields(posts::all_columns).nullable(),
                instance_users.fields(AUTHOR_COLUMNS).nullable(),
            ))
            .filter(visible_to_current_user!(
                $user,
                instance_posts,
                instance_users
            ))
            .filter(posts::user_id.is_not_null().or(posts::response_count.gt(0)))
            .filter(event_instances::ends_at.gt(ends_after))
            .order(event_instances::starts_at)
    }};
}

macro_rules! marshalable_event_data {
    ($event_data:expr) => {{
        $event_data
            .iter()
            .map(
                |(instance, event, event_post, event_author, instance_post, instance_author)| {
                    info!("instance: {:?}", instance);
                    MarshalableEvent(
                        event.clone(),
                        MarshalablePost(event_post.clone(), event_author.clone(), None, vec![]),
                        vec![MarshalableEventInstance(
                            instance.clone(),
                            instance_post
                                .clone()
                                .map(|p| MarshalablePost(p, instance_author.clone(), None, vec![])),
                        )],
                    )
                },
            )
            .collect()
    }};
}

fn get_public_and_following_events(
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
    filter: Option<TimeFilter>,
) -> Result<Vec<MarshalableEvent>, Status> {
    let query = select_events_instancewise!(user, filter);
    let binding = query.limit(20).load::<EventLoadData>(conn).unwrap();
    let event_data: Vec<&EventLoadData> = binding.iter().collect();

    Ok(marshalable_event_data!(event_data))
}

fn get_user_events(
    user_id: i64,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
    filter: Option<TimeFilter>,
) -> Result<Vec<MarshalableEvent>, Status> {
    let query = select_events_instancewise!(user, filter).filter(posts::user_id.eq(user_id));
    let binding = query.limit(20).load::<EventLoadData>(conn).unwrap();
    let event_data: Vec<&EventLoadData> = binding.iter().collect();

    Ok(marshalable_event_data!(event_data))
}

fn get_event_by_instance_id(
    user: &Option<&models::User>,
    instance_id: &str,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableEvent>, Status> {
    let instance = models::get_event_instance(instance_id.to_string().to_db_id_or_err("instance_id")?, user, conn)?;
    get_event_by_id(user, &instance.event_id.to_proto_id(), conn)
}

fn get_event_by_id(
    user: &Option<&models::User>,
    event_id: &str,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableEvent>, Status> {
    let event_db_id = match event_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => return Err(Status::new(Code::InvalidArgument, "post_id_invalid")),
    };
    let event = events::table
        .inner_join(posts::table.on(events::post_id.eq(posts::id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .left_join(
            follows::table.on(posts::user_id.eq(follows::target_user_id.nullable()).and(
                follows::user_id
                    .nullable()
                    .eq(user.as_ref().map(|u| u.id).unwrap_or(0)),
            )),
        )
        .select((
            events::all_columns,
            posts::all_columns,
            AUTHOR_COLUMNS.nullable(),
        ))
        .filter(events::id.eq(event_db_id))
        .filter(visible_to_current_user!(user, None, None))
        .get_result::<(models::Event, models::Post, Option<models::Author>)>(conn)
        .map(|(event, event_post, author)| {
            let instances = models::get_event_instances(event_db_id, user, conn).unwrap_or(vec![]);
            MarshalableEvent(
                event,
                MarshalablePost(event_post, author, None, vec![]),
                instances
                    .iter()
                    .map(|(instance, instance_post, instance_author)| {
                        MarshalableEventInstance(
                            instance.clone(),
                            instance_post
                                .clone()
                                .map(|p| MarshalablePost(p, instance_author.clone(), None, vec![])),
                        )
                    })
                    .collect(),
            )
        });

    event
        .map(|e| vec![e])
        .map_err(|_| Status::new(Code::NotFound, "event_not_found"))
}


macro_rules! visible_to_current_group_user {
    ($user:expr, $instance_posts:expr, $instance_users:expr) => {{
        posts::visibility
            .eq_any(public_string_visibilities($user))
            .or(posts::visibility
                .eq(Visibility::Limited.to_string_visibility()))
            // .or(posts::visibility
            //     .eq(Visibility::Private.to_string_visibility())
            //     .and(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
            .or(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0)))
    }};
}
macro_rules! select_group_events_instancewise {
    ($user:expr, $timefilter:expr, $group_id:expr) => {{
        let ends_after = $timefilter
            .map(|f| f.ends_after.map(|t| t.to_db()))
            .flatten()
            .unwrap_or(SystemTime::now());
        println!("ends_after={:?}", ends_after);

        let instance_posts = alias!(posts as instance_posts);
        let instance_users = alias!(users as instance_users);
        let instance_group_posts = alias!(group_posts as instance_group_posts);

        event_instances::table
            .inner_join(events::table.on(events::id.eq(event_instances::event_id)))
            .inner_join(posts::table.on(posts::id.eq(events::post_id)))
            .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
            .left_join(
                follows::table.on(posts::user_id.eq(follows::target_user_id.nullable()).and(
                    follows::user_id
                        .nullable()
                        .eq($user.as_ref().map(|u| u.id).unwrap_or(0)),
                )),
            )
            .left_join(
                instance_posts
                    .on(event_instances::post_id.eq(instance_posts.field(posts::id).nullable())),
            )
            .left_join(
                instance_users.on(instance_posts
                    .field(posts::user_id)
                    .eq(instance_users.field(users::id).nullable())),
            )
            .left_join(group_posts::table.on(group_posts::post_id.eq(posts::id)))
            .left_join(
                instance_group_posts.on(instance_posts
                    .field(posts::id)
                    .eq(instance_group_posts.field(group_posts::post_id))),
            )
            .select((
                event_instances::all_columns,
                events::all_columns,
                posts::all_columns,
                AUTHOR_COLUMNS.nullable(),
                instance_posts.fields(posts::all_columns).nullable(),
                instance_users.fields(AUTHOR_COLUMNS).nullable(),
            ))
            .filter(visible_to_current_group_user!(
                $user,
                instance_posts,
                instance_users
            ))
            .filter(
                group_posts::group_id.eq($group_id).or(instance_group_posts
                    .field(group_posts::group_id)
                    .eq($group_id)),
            )
            .filter(posts::user_id.is_not_null().or(posts::response_count.gt(0)))
            .filter(event_instances::ends_at.gt(ends_after))
            .order(event_instances::starts_at)
    }};
}

fn get_group_events(
    group_id: i64,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
    filter: Option<TimeFilter>,
) -> Result<Vec<MarshalableEvent>, Status> {
    let group = models::get_group(group_id, conn)
        .map_err(|_| Status::new(Code::NotFound, "group_not_found"))?;

    let membership = match user {
        Some(user) => match models::get_membership(group_id, user.id, conn).ok() {
            Some(membership) if membership.passes() => Some(membership),
            _ => None,
        },
        None => None,
    };

    // let permissions = membership.map(|m| m.permissions).unwrap_or(group.non_member_permissions);

    validate_group_permission(&group, &membership.as_ref(), user, Permission::ViewEvents)?;

    let result = match (group.visibility.to_proto_visibility().unwrap(), user) {
        (Visibility::GlobalPublic, _) | (_, Some(_)) => {
            let query = select_group_events_instancewise!(user, filter, group_id);
            let binding = query.limit(20).load::<EventLoadData>(conn).unwrap();
            let event_data: Vec<&EventLoadData> = binding.iter().collect();

            marshalable_event_data!(event_data)
        },
        (_, None) => vec![],
    };

    Ok(result)
}
