//! Specs for `rpcs::events::get_events`, covering every branch of the `match` in `get_events()`
//! plus the visibility/moderation rules baked into `query_visible_events!` (see the macro in
//! `get_events.rs`). The one rule that's easy to miss reading the RPC in isolation: an event's
//! overall visibility is the *intersection* of its container `Event` post's
//! visibility/moderation and each individual `EventInstance`'s own post's - `query_visible_events!`
//! filters on both independently (see `requires_both_container_and_instance_post_to_pass`, below).
//!
//! Each test opens its own connection to `TEST_DATABASE_URL` and runs entirely inside a
//! `test_transaction`, so nothing here is ever committed - tests are free to create users,
//! events, groups, etc. via `crate::tests::factories` without any cleanup step.

use std::time::{Duration, SystemTime};

use diesel::prelude::*;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::get_events;
use crate::schema::posts;
use crate::tests::factories::*;

fn ids(response: &GetEventsResponse) -> Vec<String> {
    response.events.iter().map(|e| e.id.clone()).collect()
}

fn ago(seconds: u64) -> SystemTime {
    SystemTime::now() - Duration::from_secs(seconds)
}

fn from_now(seconds: u64) -> SystemTime {
    SystemTime::now() + Duration::from_secs(seconds)
}

/// Creates a single-instance event: a `PostContext::Event` container post/`Event`, plus one
/// `PostContext::EventInstance` post/`EventInstance`. `event_opts`/`instance_opts` each default
/// to `ServerPublic`/`Unmoderated` (see `EventOpts`/`EventInstanceOpts`) - tests override
/// whichever side (container vs. instance) they're actually exercising.
fn create_simple_event(
    conn: &mut crate::db_connection::PgPooledConnection,
    author: &crate::models::User,
    event_opts: EventOpts,
    instance_opts: EventInstanceOpts,
) -> (crate::models::Event, crate::models::EventInstance) {
    let (event, _event_post) = create_event(conn, author, event_opts);
    let (instance, _instance_post) = create_event_instance(conn, &event, Some(author), instance_opts);
    (event, instance)
}

mod get_by_event_id {
    use super::*;

    #[test]
    fn found_returns_public_event() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbei_author1");
            let (event, _instance) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_events(
                GetEventsRequest {
                    event_id: Some(event.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            assert_eq!(response.events[0].instances.len(), 1);
            Ok(())
        });
    }

    #[test]
    fn not_found_for_nonexistent_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_events(
                GetEventsRequest {
                    event_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "event_not_found");
            Ok(())
        });
    }

    #[test]
    fn invalid_id_format() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_events(
                GetEventsRequest {
                    event_id: Some("not-valid-base58!!".to_string()),
                    ..Default::default()
                },
                &None,
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "post_id_invalid");
            Ok(())
        });
    }

    /// `query_visible_events!` filters on the container `Event` post's visibility *and* the
    /// `EventInstance`'s own post's visibility as two independent `.filter(...)` calls (i.e.
    /// ANDed) - so a `Private` container post hides the event even when its instance post is
    /// `GlobalPublic`, and vice versa. Only when both sides pass (or the requester is the author)
    /// is the event visible.
    #[test]
    fn requires_both_container_and_instance_post_to_pass() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbei_author2");
            let stranger = create_user(conn, "gbei_stranger2");

            let (private_container_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::Private,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            let (private_instance_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::Private,
                    ..Default::default()
                },
            );

            for event in [&private_container_event, &private_instance_event] {
                let hidden = get_events(
                    GetEventsRequest {
                        event_id: Some(event.id.to_proto_id()),
                        ..Default::default()
                    },
                    &Some(&stranger),
                    conn,
                );
                assert_eq!(hidden.unwrap_err().code(), Code::NotFound);

                let visible_to_author = get_events(
                    GetEventsRequest {
                        event_id: Some(event.id.to_proto_id()),
                        ..Default::default()
                    },
                    &Some(&author),
                    conn,
                )?;
                assert_eq!(ids(&visible_to_author), vec![event.id.to_proto_id()]);
            }
            Ok(())
        });
    }
}

mod get_by_instance_id {
    use super::*;

    #[test]
    fn resolves_to_the_parent_event() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbii_author1");
            let (event, instance) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_events(
                GetEventsRequest {
                    event_instance_id: Some(instance.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn not_found_for_nonexistent_instance_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_events(
                GetEventsRequest {
                    event_instance_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            );

            let err = result.unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "event_instance_not_found");
            Ok(())
        });
    }
}

mod get_by_post_id {
    use super::*;

    #[test]
    fn resolves_via_container_post_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbpi_author1");
            let (event, event_post) = create_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_event_instance(
                conn,
                &event,
                Some(&author),
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_events(
                GetEventsRequest {
                    post_id: Some(event_post.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn resolves_via_instance_post_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gbpi_author2");
            let (event, _event_post) = create_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            let (_instance, instance_post) = create_event_instance(
                conn,
                &event,
                Some(&author),
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_events(
                GetEventsRequest {
                    post_id: Some(instance_post.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn not_found_for_nonexistent_post_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let result = get_events(
                GetEventsRequest {
                    post_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            );

            assert_eq!(result.unwrap_err().code(), Code::NotFound);
            Ok(())
        });
    }
}

mod get_user_events {
    use super::*;

    #[test]
    fn scopes_to_that_authors_events() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author1 = create_user(conn, "gue_author1");
            let author2 = create_user(conn, "gue_author2");
            let (event1, _) = create_simple_event(
                conn,
                &author1,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_simple_event(
                conn,
                &author2,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = get_events(
                GetEventsRequest {
                    author_user_id: Some(author1.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![event1.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn respects_visibility_of_other_users_events() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "gue_author3");
            let (public_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            let (private_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::Private,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::Private,
                    ..Default::default()
                },
            );

            let anon_response = get_events(
                GetEventsRequest {
                    author_user_id: Some(author.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;
            assert_eq!(ids(&anon_response), vec![public_event.id.to_proto_id()]);

            let self_response = get_events(
                GetEventsRequest {
                    author_user_id: Some(author.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&author),
                conn,
            )?;
            let mut self_ids = ids(&self_response);
            self_ids.sort();
            let mut expected = vec![
                public_event.id.to_proto_id(),
                private_event.id.to_proto_id(),
            ];
            expected.sort();
            assert_eq!(self_ids, expected);
            Ok(())
        });
    }
}

mod get_group_events {
    use super::*;

    #[test]
    fn missing_group_id_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = get_events(
                GetEventsRequest {
                    listing_type: EventListingType::GroupEvents as i32,
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            Ok(())
        });
    }

    #[test]
    fn nonexistent_group_is_not_found() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = get_events(
                GetEventsRequest {
                    listing_type: EventListingType::GroupEvents as i32,
                    group_id: Some(999_999_999i64.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::NotFound);
            assert_eq!(err.message(), "group_not_found");
            Ok(())
        });
    }

    #[test]
    fn permission_denied_for_private_group_non_member() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let group = create_group(conn, "ge-private1", GroupOpts::default());
            let stranger = create_user(conn, "ge_stranger1");

            let err = get_events(
                GetEventsRequest {
                    listing_type: EventListingType::GroupEvents as i32,
                    group_id: Some(group.id.to_proto_id()),
                    ..Default::default()
                },
                &Some(&stranger),
                conn,
            )
            .unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            Ok(())
        });
    }

    #[test]
    fn returns_events_shared_to_the_group_with_passing_moderation() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "ge_author2");
            let group = create_group(
                conn,
                "ge-public2",
                GroupOpts {
                    non_member_permissions: vec![Permission::ViewPosts],
                },
            );
            let (approved_event, approved_post) = create_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_event_instance(
                conn,
                &approved_event,
                Some(&author),
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &approved_post, &group, &author, Moderation::Approved);

            let (pending_event, pending_post) = create_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_event_instance(
                conn,
                &pending_event,
                Some(&author),
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_group_post(conn, &pending_post, &group, &author, Moderation::Pending);

            let response = get_events(
                GetEventsRequest {
                    listing_type: EventListingType::GroupEvents as i32,
                    group_id: Some(group.id.to_proto_id()),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            assert_eq!(ids(&response), vec![approved_event.id.to_proto_id()]);
            Ok(())
        });
    }
}

mod default_listing {
    use super::*;

    #[test]
    fn orders_by_starts_at() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "dl_author1");
            let (later_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    starts_at: from_now(7200),
                    ends_at: from_now(10800),
                
                    ..Default::default()
                },
            );
            let (sooner_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    starts_at: from_now(60),
                    ends_at: from_now(120),
                
                    ..Default::default()
                },
            );

            let response = get_events(GetEventsRequest::default(), &None, conn)?;

            assert_eq!(
                ids(&response),
                vec![sooner_event.id.to_proto_id(), later_event.id.to_proto_id()]
            );
            Ok(())
        });
    }

    /// `time_filter.ends_after` filters on `event_instances.ends_at` directly (see
    /// `query_visible_events!`'s `.filter(event_instances::ends_at.gt(ends_after))`) - an
    /// instance that already ended before the given cutoff is excluded even though its `Event`
    /// itself is otherwise fully visible.
    #[test]
    fn excludes_instances_ending_before_the_time_filters_ends_after() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "dl_author2");
            let (past_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    starts_at: ago(7200),
                    ends_at: ago(3600),
                
                    ..Default::default()
                },
            );
            let (future_event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    starts_at: from_now(3600),
                    ends_at: from_now(7200),
                
                    ..Default::default()
                },
            );

            let response = get_events(
                GetEventsRequest {
                    time_filter: Some(TimeFilter {
                        ends_after: Some(SystemTime::now().to_proto()),
                        ..Default::default()
                    }),
                    ..Default::default()
                },
                &None,
                conn,
            )?;

            let response_ids = ids(&response);
            assert!(response_ids.contains(&future_event.id.to_proto_id()));
            assert!(!response_ids.contains(&past_event.id.to_proto_id()));
            Ok(())
        });
    }

    #[test]
    fn limited_event_visible_to_follower_only() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let follower = create_user(conn, "dl_follower3");
            let followed = create_user(conn, "dl_followed3");
            let stranger = create_user(conn, "dl_stranger3");
            create_follow(conn, &follower, &followed);

            let (limited_event, _) = create_simple_event(
                conn,
                &followed,
                EventOpts {
                    visibility: Visibility::Limited,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::Limited,
                    ..Default::default()
                },
            );

            let visible = get_events(GetEventsRequest::default(), &Some(&follower), conn)?;
            assert_eq!(ids(&visible), vec![limited_event.id.to_proto_id()]);

            let hidden = get_events(GetEventsRequest::default(), &Some(&stranger), conn)?;
            assert!(ids(&hidden).is_empty());
            Ok(())
        });
    }
}

/// Specs for `EVENT_TEXT_SEARCH` (`get_search_events` in `get_events.rs`) - mirrors
/// `get_posts_tests::text_search` closely, but additionally covers matching via the parent
/// `Event`'s own Post (not just the `EventInstance`'s own Post) and still respecting the request's
/// `time_filter` alongside `search_text`.
mod text_search {
    use super::*;

    fn search(
        conn: &mut crate::db_connection::PgPooledConnection,
        search_text: Option<&str>,
        author_user_id: Option<String>,
        time_filter: Option<TimeFilter>,
        user: &Option<&crate::models::User>,
    ) -> Result<GetEventsResponse, Status> {
        get_events(
            GetEventsRequest {
                listing_type: EventListingType::EventTextSearch as i32,
                search_text: search_text.map(str::to_string),
                author_user_id,
                time_filter,
                ..Default::default()
            },
            user,
            conn,
        )
    }

    #[test]
    fn missing_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = search(conn, None, None, None, &None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    #[test]
    fn blank_search_text_is_invalid_argument() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let err = search(conn, Some("   "), None, None, &None).unwrap_err();
            assert_eq!(err.code(), Code::InvalidArgument);
            assert_eq!(err.message(), "search_text_required");
            Ok(())
        });
    }

    #[test]
    fn matches_instance_post_title() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_instance_title_author");
            let (event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("Recurring Meetup".to_string()),
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("A one-off about xylophones".to_string()),
                    ..Default::default()
                },
            );

            let response = search(conn, Some("xylophones"), None, None, &None)?;
            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    /// The instance's own Post rarely overrides its parent Event's title/content (see
    /// `Components.Events.meaningfulPost`) - searching the *Event's* title must still find it.
    #[test]
    fn matches_parent_event_post_title() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_event_title_author");
            let (event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("Farmers Market".to_string()),
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = search(conn, Some("farmers"), None, None, &None)?;
            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn matches_author_username() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "zzyzxevtauthor");
            let (event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = search(conn, Some("zzyzxevtauthor"), None, None, &None)?;
            assert_eq!(ids(&response), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    #[test]
    fn scoped_by_author_user_id() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author1 = create_user(conn, "search_evt_scope_author1");
            let author2 = create_user(conn, "search_evt_scope_author2");
            let (event1, _) = create_simple_event(
                conn,
                &author1,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("wobblefest from author1".to_string()),
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            create_simple_event(
                conn,
                &author2,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("wobblefest from author2".to_string()),
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );

            let response = search(
                conn,
                Some("wobblefest"),
                Some(author1.id.to_proto_id()),
                None,
                &None,
            )?;
            assert_eq!(ids(&response), vec![event1.id.to_proto_id()]);
            Ok(())
        });
    }

    // `query_visible_events!`'s default `ends_after` (used when `time_filter` is omitted
    // entirely) is a near-epoch fallback, not "now" - see that macro's own doc - so this drives
    // both windows via an explicit `time_filter` rather than relying on the default to exclude an
    // already-ended instance.
    #[test]
    fn respects_time_filter() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_evt_time_author");
            let (event, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("wigglecon".to_string()),
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    starts_at: ago(7200),
                    ends_at: ago(3600),
                    ..Default::default()
                },
            );

            // "Ends after now" excludes an instance that already ended an hour ago.
            let excluded = search(
                conn,
                Some("wigglecon"),
                None,
                Some(TimeFilter {
                    ends_after: Some(SystemTime::now().to_proto()),
                    ..Default::default()
                }),
                &None,
            )?;
            assert!(ids(&excluded).is_empty());

            // "Ends after 2 hours ago" (before the instance's own ends_at) includes it.
            let included = search(
                conn,
                Some("wigglecon"),
                None,
                Some(TimeFilter {
                    ends_after: Some(ago(7200).to_proto()),
                    ..Default::default()
                }),
                &None,
            )?;
            assert_eq!(ids(&included), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }

    /// Results are ordered by match quality first (title, weight 'A', outranks a mere content
    /// mention, weight 'B'), falling back to recency - mirrors
    /// `get_posts_tests::text_search::orders_by_relevance_before_recency`.
    #[test]
    fn orders_by_relevance_before_recency() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_evt_relevance_author");
            let (title_match, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("gerbilmongoose special".to_string()),
                    starts_at: from_now(600),
                    ends_at: from_now(1200),
                    ..Default::default()
                },
            );
            let (content_match, _) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    starts_at: from_now(10),
                    ends_at: from_now(20),
                    ..Default::default()
                },
            );
            diesel::update(posts::table.filter(posts::id.eq(content_match.post_id)))
                .set(posts::content.eq("an event that mentions gerbilmongoose in passing"))
                .execute(conn)
                .expect("failed to update test post content");

            let response = search(conn, Some("gerbilmongoose"), None, None, &None)?;

            assert_eq!(
                ids(&response),
                vec![title_match.id.to_proto_id(), content_match.id.to_proto_id()]
            );
            Ok(())
        });
    }

    /// `event_instances.search_text` is a denormalized column kept in sync by triggers (see
    /// `backend/migrations/2026-07-30-170000_add_search_text_to_event_instances`) - editing
    /// either the instance's own Post or its parent Event's Post *after* creation must still be
    /// searchable, not just the text present at insert time.
    #[test]
    fn editing_a_posts_title_after_creation_updates_search_text() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "search_evt_edit_author");
            let (event, instance) = create_simple_event(
                conn,
                &author,
                EventOpts {
                    visibility: Visibility::GlobalPublic,
                    title: Some("Book Club".to_string()),
                    ..Default::default()
                },
                EventInstanceOpts {
                    visibility: Visibility::GlobalPublic,
                    ..Default::default()
                },
            );
            assert!(search(conn, Some("wobbledoo"), None, None, &None)?
                .events
                .is_empty());

            // Editing the instance's own Post.
            diesel::update(posts::table.filter(posts::id.eq(instance.post_id)))
                .set(posts::title.eq("Wobbledoo Chapter"))
                .execute(conn)
                .expect("failed to update test instance post title");
            let via_instance_edit = search(conn, Some("wobbledoo"), None, None, &None)?;
            assert_eq!(ids(&via_instance_edit), vec![event.id.to_proto_id()]);

            // Editing the parent Event's own Post.
            diesel::update(posts::table.filter(posts::id.eq(event.post_id)))
                .set(posts::title.eq("Fizzbuzz Society"))
                .execute(conn)
                .expect("failed to update test event post title");
            let via_event_edit = search(conn, Some("fizzbuzz"), None, None, &None)?;
            assert_eq!(ids(&via_event_edit), vec![event.id.to_proto_id()]);
            Ok(())
        });
    }
}
