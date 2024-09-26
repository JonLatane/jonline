use std::time::SystemTime;

use diesel::*;
use log::info;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::*;
use crate::marshaling::*;
use crate::models;
use crate::models::AUTHOR_COLUMNS;
use crate::models::{get_group, get_membership};
use crate::protos::*;
use crate::rpcs::validate_group_permission;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::*;

const PAGE_SIZE: i64 = 1000;

type EventLoadData = (
    models::EventInstance,
    models::Event,
    models::Post,
    Option<models::Author>,
    models::Post,
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
        request.to_owned().post_id,
    ) {
        // TODO: implement the other listing types
        (_, Some(event_id), _, _, _) => get_event_by_id(&user, &event_id, conn)?,
        (_, _, Some(instance_id), _, _) => get_event_by_instance_id(&user, &instance_id, conn)?,
        (EventListingType::GroupEvents, _, _, _, _) => match request.group_id {
            Some(group_id) => get_group_events(
                group_id.to_db_id_or_err("group_id")?,
                &user,
                conn,
                request.time_filter,
            )?,
            _ => return Err(Status::new(Code::InvalidArgument, "group_id_invalid")),
        },
        (_, _, _, Some(author_user_id), _) => get_user_events(
            author_user_id.to_db_id_or_err("author_user_id")?,
            user,
            conn,
            request.time_filter,
        )?,
        (_, _, _, _, Some(post_id)) => get_event_by_post_id(&user, &post_id, conn)?,
        _ => get_public_and_following_events(&user, conn, request.time_filter)?,
    };
    Ok(GetEventsResponse {
        events: convert_events(&result, conn),
    })
}

macro_rules! query_visible_events {
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
            .left_join(group_posts::table.on(posts::id.eq(group_posts::post_id)))
            .left_join(
                memberships::table.on(memberships::user_id
                    .eq($user.as_ref().map(|u| u.id).unwrap_or(0))
                    .and(memberships::group_id.eq(group_posts::group_id))),
            )
            .inner_join(
                instance_posts.on(event_instances::post_id.eq(instance_posts.field(posts::id))),
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
                instance_posts.fields(posts::all_columns),
                instance_users.fields(AUTHOR_COLUMNS).nullable(),
            ))
            .filter(
                posts::visibility
                    .eq_any(public_string_visibilities($user))
                    .or(posts::visibility
                        .eq(Visibility::Limited.to_string_visibility())
                        .and(follows::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    .or(posts::visibility
                        .eq(Visibility::Limited.to_string_visibility())
                        .and(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
                        .and(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
                        .and(memberships::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    .or(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))),
            )
            .filter(
                instance_posts
                    .field(posts::visibility)
                    .eq_any(public_string_visibilities($user))
                    .or(instance_posts
                        .field(posts::visibility)
                        .eq(Visibility::Limited.to_string_visibility())
                        .and(follows::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    .or(instance_posts
                        .field(posts::visibility)
                        .eq(Visibility::Limited.to_string_visibility())
                        .and(memberships::user_moderation.eq_any(PASSING_MODERATIONS))
                        .and(memberships::group_moderation.eq_any(PASSING_MODERATIONS))
                        .and(memberships::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))))
                    .or(instance_posts
                        .field(posts::user_id)
                        .eq($user.as_ref().map(|u| u.id).unwrap_or(0))),
            )
            .filter(posts::user_id.is_not_null())
            // .filter(posts::user_id.is_not_null().or(posts::response_count.gt(0)))
            .filter(event_instances::ends_at.gt(ends_after))
            .order(event_instances::starts_at)
            .distinct()
            .limit(PAGE_SIZE)
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
                            MarshalablePost(
                                instance_post.clone(),
                                instance_author.clone(),
                                None,
                                vec![],
                            ),
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
    let query = query_visible_events!(user, filter);
    let binding = query.load::<EventLoadData>(conn).unwrap();
    let event_data: Vec<&EventLoadData> = binding.iter().collect();

    Ok(marshalable_event_data!(event_data))
}

fn get_user_events(
    user_id: i64,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
    filter: Option<TimeFilter>,
) -> Result<Vec<MarshalableEvent>, Status> {
    let query = query_visible_events!(user, filter).filter(posts::user_id.eq(user_id));
    let binding = query.load::<EventLoadData>(conn).unwrap();
    let event_data: Vec<&EventLoadData> = binding.iter().collect();

    Ok(marshalable_event_data!(event_data))
}

fn get_event_by_instance_id(
    user: &Option<&models::User>,
    instance_id: &str,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableEvent>, Status> {
    let instance = models::get_event_instance(
        instance_id.to_string().to_db_id_or_err("instance_id")?,
        user,
        conn,
    )?;
    get_event_by_id(user, &instance.event_id.to_proto_id(), conn)
}

fn get_event_by_post_id(
    user: &Option<&models::User>,
    post_id: &str,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableEvent>, Status> {
    let post_db_id = post_id.to_string().to_db_id_or_err("post_id")?;
    let event_id = match event_instances::table
        .left_join(events::table.on(events::id.eq(event_instances::event_id)))
        .select(event_instances::event_id)
        .filter(
            event_instances::post_id
                .eq(post_db_id)
                .or(events::post_id.eq(post_db_id)),
        )
        .first::<i64>(conn)
    {
        Ok(event_id) => event_id,
        Err(_) => match events::table
            .select(events::id)
            .filter(events::post_id.eq(post_db_id))
            .first::<i64>(conn)
        {
            Ok(event_id) => event_id,
            Err(_) => return Err(Status::new(Code::NotFound, "event_instance_not_found")),
        },
    };
    get_event_by_id(user, &event_id.to_proto_id(), conn)
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
    let event = query_visible_events!(user, None::<TimeFilter>)
        .select((
            events::all_columns,
            posts::all_columns,
            AUTHOR_COLUMNS.nullable(),
        ))
        .filter(events::id.eq(event_db_id))
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
                            MarshalablePost(
                                instance_post.clone(),
                                instance_author.clone(),
                                None,
                                vec![],
                            ),
                        )
                    })
                    .collect(),
            )
        });

    event
        .map(|e| vec![e])
        .map_err(|_| Status::new(Code::NotFound, "event_not_found"))
}

fn get_group_events(
    group_id: i64,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
    filter: Option<TimeFilter>,
) -> Result<Vec<MarshalableEvent>, Status> {
    let group = get_group(group_id, conn);
    match group {
        Ok(group) => {
            let membership = user
                .map(|u| get_membership(group_id, u.id, conn).ok())
                .flatten();
            validate_group_permission(&group, &membership.as_ref(), user, Permission::ViewPosts)?;

            let query =
                query_visible_events!(user, filter).filter(group_posts::group_id.eq(group_id));
            let binding = query.load::<EventLoadData>(conn).unwrap();
            let event_data: Vec<&EventLoadData> = binding.iter().collect();

            Ok(marshalable_event_data!(event_data))
        }
        Err(_) => Err(Status::new(Code::NotFound, "group_not_found")),
    }
}
