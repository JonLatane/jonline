use diesel::*;
use diesel_full_text_search::{
    configuration::TsConfigurationByName, to_tsquery_with_search_config, ts_rank_cd,
    TsVectorExtensions,
};
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
use prost_wkt_types::Timestamp;

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
    let result: Vec<MarshalableEvent> = if !request.event_instance_post_ids.is_empty() {
        get_events_by_instance_post_ids(&user, &request.event_instance_post_ids, conn)?
    } else {
        match (
            request.listing_type(),
            request.to_owned().event_id,
            request.to_owned().event_instance_id,
            request.to_owned().author_user_id,
            request.to_owned().post_id,
        ) {
            // TODO: implement the other listing types
            (_, Some(event_id), _, _, _) => get_event_by_id(&user, &event_id, conn)?,
            (_, _, Some(instance_id), _, _) => get_event_by_instance_id(&user, &instance_id, conn)?,
            (EventListingType::EventTextSearch, _, _, _, _) => {
                get_search_events(&request, &user, conn)?
            }
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
        }
    };
    Ok(GetEventsResponse {
        events: convert_events(&result, conn),
    })
}

macro_rules! query_visible_events {
    ($user:expr, $timefilter:expr) => {{
        let instance_posts = alias!(posts as instance_posts);
        let instance_users = alias!(users as instance_users);

        let ends_after = $timefilter
            .map(|f| f.ends_after.map(|t| t.to_db()))
            .flatten()
            .unwrap_or(
                Timestamp {
                    seconds: 100,
                    nanos: 0,
                }
                .to_db(),
            );
        info!("query_visible_events ends_after={:?}", ends_after);

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
                models::EVENT_INSTANCE_COLUMNS,
                events::all_columns,
                models::POST_COLUMNS,
                AUTHOR_COLUMNS.nullable(),
                instance_posts.fields(models::POST_COLUMNS),
                instance_users.fields(AUTHOR_COLUMNS).nullable(),
            ))
            //TODO UNCOMMENT THISSSS
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
            .filter(
                posts::moderation
                    .eq_any(PASSING_MODERATIONS)
                    .or(posts::user_id.eq($user.as_ref().map(|u| u.id).unwrap_or(0))),
            )
            .filter(posts::user_id.is_not_null())
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
                        MarshalablePost(
                            event_post.clone(),
                            event_author.clone(),
                            None,
                            None,
                            vec![],
                        ),
                        vec![MarshalableEventInstance(
                            instance.clone(),
                            MarshalablePost(
                                instance_post.clone(),
                                instance_author.clone(),
                                None,
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

// Full-text search across accessible EventInstances' own-Post and parent-Event-Post title/
// content/author username/author real name (see event_instances.search_text's own doc,
// backend/migrations/2026-07-30-170000_add_search_text_to_event_instances). Still respects
// `request.time_filter` -- the caller's current Upcoming/After-date tab, same as every other
// listing type here -- and, when scoped to an author, filters on the denormalized
// `event_instances::user_id` -- matching the composite GIN index added alongside search_text, so
// each of those filter combinations is served by a single index scan.
fn get_search_events(
    request: &GetEventsRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableEvent>, Status> {
    let search_text = request
        .search_text
        .as_deref()
        .map(str::trim)
        .filter(|search_text| !search_text.is_empty())
        .ok_or(Status::new(Code::InvalidArgument, "search_text_required"))?;
    let prefix_query_text = prefix_tsquery_text(search_text);
    if prefix_query_text.is_empty() {
        return Err(Status::new(Code::InvalidArgument, "search_text_required"));
    }
    let author_user_id = request
        .author_user_id
        .as_ref()
        .map(|author_user_id| author_user_id.to_db_id_or_err("author_user_id"))
        .transpose()?;

    // Prefix (not just whole/stemmed lexeme) matching, "simple" config -- mirrors
    // get_search_posts's own tsquery setup (see that function's doc comment for why).
    let search_query =
        to_tsquery_with_search_config(TsConfigurationByName("simple"), prefix_query_text.clone());
    // A second, independent tsquery expression for the rank calculation below -- `search_query`
    // above is consumed by `.matches(...)`, and the generated tsquery expression type isn't Clone.
    let rank_query =
        to_tsquery_with_search_config(TsConfigurationByName("simple"), prefix_query_text);

    // `query_visible_events!`'s joins can produce more than one row per matching instance, so it
    // applies `SELECT DISTINCT` -- which Postgres requires every ORDER BY expression to appear in
    // the select list for. That's fine for the other GetEvents branches (they order by a plain
    // column), but `ts_rank_cd(...)` takes a bind parameter that can't structurally match between
    // a `.select(...)` and an `.order(...)` (see get_search_posts's own doc comment for the full
    // explanation). So this resolves matching instance ids DISTINCT-ly first (a plain
    // `event_instances::id` has no such problem), then ranks and orders the (already-unique)
    // matches in a second, DISTINCT-free query.
    // `query_visible_events!` bakes in `.order(event_instances::starts_at)` (for its own normal
    // listing callers) ahead of its own `.distinct()` -- Postgres requires every ORDER BY
    // expression to appear in the SELECT list under SELECT DISTINCT, so once `.select(...)` below
    // narrows that list down to just `id`, the order has to be overridden to match (a plain `id`
    // order is fine here regardless -- this query only collects ids, `binding` below is what's
    // actually ordered by rank).
    let mut matching_instance_ids = query_visible_events!(user, request.time_filter)
        .select(event_instances::id)
        .order(event_instances::id)
        .filter(event_instances::search_text.matches(search_query))
        .into_boxed();

    if let Some(author_user_id) = author_user_id {
        matching_instance_ids =
            matching_instance_ids.filter(event_instances::user_id.eq(author_user_id));
    }

    let instance_posts = alias!(posts as instance_posts);
    let instance_users = alias!(users as instance_users);

    let binding: Vec<EventLoadData> = event_instances::table
        .inner_join(events::table.on(events::id.eq(event_instances::event_id)))
        .inner_join(posts::table.on(posts::id.eq(events::post_id)))
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .inner_join(
            instance_posts.on(event_instances::post_id.eq(instance_posts.field(posts::id))),
        )
        .left_join(
            instance_users.on(instance_posts
                .field(posts::user_id)
                .eq(instance_users.field(users::id).nullable())),
        )
        .filter(event_instances::id.eq_any(matching_instance_ids))
        .select((
            models::EVENT_INSTANCE_COLUMNS,
            events::all_columns,
            models::POST_COLUMNS,
            AUTHOR_COLUMNS.nullable(),
            instance_posts.fields(models::POST_COLUMNS),
            instance_users.fields(AUTHOR_COLUMNS).nullable(),
        ))
        // Search results are ordered by match quality first, falling back to start time to keep
        // ordering stable across the (common, with prefix matching) rank ties -- mirrors
        // get_search_posts's own recency fallback.
        .order(ts_rank_cd(event_instances::search_text, rank_query).desc())
        .then_order_by(event_instances::starts_at.desc())
        .limit(PAGE_SIZE)
        .load::<EventLoadData>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_events"))?;
    let event_data: Vec<&EventLoadData> = binding.iter().collect();

    Ok(marshalable_event_data!(event_data))
}

// Batch lookup for `GetEventsRequest.event_instance_post_ids` -- e.g. the Elm
// frontend's Starred panel (`Shared.StarredPanel`), which already has a flat
// list of starred `Post` ids (some of which may turn out to be an
// `EventInstance`'s own Post, per `PostContext.EVENT_INSTANCE`) and wants
// their owning `Event`/`EventInstance` data in one request rather than one
// `event_instance_id`-scoped `GetEvents` call per starred post. Unlike
// `get_event_by_id` (which returns the *whole* `Event` with every one of its
// instances, for the single-event detail page's date-picker strip), this
// mirrors `get_public_and_following_events`'s "one `Event` entry per matching
// `EventInstance`" shape (see `marshalable_event_data!`) -- each requested
// post id maps to exactly one instance, so the response shouldn't bloat with
// sibling instances the caller never asked about. `event_instances::post_id`
// is a plain (unaliased) column on the base `event_instances::table` the
// `query_visible_events!` macro already joins in, so -- same as
// `get_group_events`'s own extra `.filter()`s -- this can filter on it
// directly without needing the macro to expose its internal `instance_posts`
// alias.
fn get_events_by_instance_post_ids(
    user: &Option<&models::User>,
    post_ids: &[String],
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableEvent>, Status> {
    let instance_post_db_ids: Vec<i64> = post_ids
        .iter()
        .filter_map(|post_id| post_id.to_string().to_db_id().ok())
        .collect();
    if instance_post_db_ids.is_empty() {
        return Ok(vec![]);
    }

    let query = query_visible_events!(user, None::<TimeFilter>)
        .filter(event_instances::post_id.eq_any(instance_post_db_ids));
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
    info!("get_event_by_instance_id instance: {:?}", instance);
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
    info!("get_event_by_id event_db_id: {}", event_db_id);
    let query = query_visible_events!(user, None::<TimeFilter>).filter(events::id.eq(event_db_id));
    let binding = query.load::<EventLoadData>(conn).unwrap();
    let event_data: Vec<&EventLoadData> = binding.iter().collect();
    info!("get_event_by_id event_data: {:?}", event_data);
    if event_data.is_empty() {
        // info!("get_event_by_id event_data.is_empty");
        return Err(Status::new(Code::NotFound, "event_not_found"));
    }

    let event_model = event_data[0].1.clone();
    let event_post = event_data[0].2.clone();
    let event_author = event_data[0].3.clone();

    let event = MarshalableEvent(
        event_model,
        MarshalablePost(event_post, event_author, None, None, vec![]),
        event_data
            .iter()
            .map(
                |(instance, _event, _event_post, _event_author, instance_post, instance_author)| {
                    MarshalableEventInstance(
                        instance.clone(),
                        MarshalablePost(
                            instance_post.clone(),
                            instance_author.clone(),
                            None,
                            None,
                            vec![],
                        ),
                    )
                },
            )
            .collect(),
    );
    info!("get_event_by_id event: {:?}", event);

    Ok(vec![event])
    // .map(|e| vec![e])
    // .map_err(|_| Status::new(Code::NotFound, "event_not_found"))
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

            let query = query_visible_events!(user, filter)
                .filter(group_posts::group_id.eq(group_id))
                .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS));
            let binding = query.load::<EventLoadData>(conn).unwrap();
            let event_data: Vec<&EventLoadData> = binding.iter().collect();

            Ok(marshalable_event_data!(event_data))
        }
        Err(_) => Err(Status::new(Code::NotFound, "group_not_found")),
    }
}
