//! Specs for `update_event`'s instance-merging behavior (`update_event_instances`, in
//! `rpcs/events/update_event.rs`): given a request's `instances` list, each entry is matched
//! against the event's existing instances by id, then either updated in place, created fresh, or
//! (if an existing instance's id is missing from the request) deleted. These specs exercise that
//! matching logic directly -- `create_event_sets_event_count_once_and_event_instance_count_per_instance`
//! in `user_counts_tests` only covers the pure-create path (`CreateEvent`), not `UpdateEvent`'s
//! three-way merge.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use diesel::prelude::*;
use tonic::Status;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::update_event;
use crate::schema::{event_instances, posts, users};
use crate::tests::factories::*;

/// A `SystemTime` truncated to whole seconds, `offset_secs` in the future. `Timestamp::to_proto`
/// (see `time_marshaling.rs`) always zeroes out sub-second precision, so any `SystemTime` built
/// from sub-second-precision data (e.g. `SystemTime::now()` directly) would silently lose that
/// precision on its way through a request -- comparing against it post-update would then require
/// truncating the expected value too. Building already-whole-second timestamps up front keeps the
/// round trip lossless and the assertions exact.
fn whole_second_instant(offset_secs: u64) -> SystemTime {
    let now_secs = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    UNIX_EPOCH + Duration::from_secs(now_secs + offset_secs)
}

fn event_instance_row(conn: &mut crate::db_connection::PgPooledConnection, id: i64) -> Option<models::EventInstance> {
    event_instances::table
        .select(models::EVENT_INSTANCE_COLUMNS)
        .filter(event_instances::id.eq(id))
        .first::<models::EventInstance>(conn)
        .ok()
}

fn post_row(conn: &mut crate::db_connection::PgPooledConnection, id: i64) -> models::Post {
    posts::table
        .select(models::POST_COLUMNS)
        .filter(posts::id.eq(id))
        .first::<models::Post>(conn)
        .expect("post should exist")
}

/// `update_event`'s own return value (`super::get_events(...).events[0]`, see `update_event.rs`
/// line ~60) round-trips through the read path's own visibility/ownership rules, which aren't
/// what these specs are about -- so assertions here go against `event_instances`/`posts` rows
/// directly (matching `delete_event_tests`' convention), and only use the RPC's return value for
/// instance-count/id checks it's convenient for.
#[test]
fn updating_an_existing_instance_in_place_preserves_its_id_and_persists_changed_fields() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_inplace_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts::default());
        let (instance, _instance_post) = create_event_instance(
            conn,
            &event,
            Some(&author),
            EventInstanceOpts {
                starts_at: whole_second_instant(3600),
                ends_at: whole_second_instant(7200),
                ..Default::default()
            },
        );

        let new_starts_at = whole_second_instant(10_000);
        let new_ends_at = whole_second_instant(20_000);
        let new_location = Location {
            uniformly_formatted_address: "123 Test St".to_string(),
            ..Default::default()
        };

        let updated = update_event(
            Event {
                id: event.id.to_proto_id(),
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![EventInstance {
                    id: instance.id.to_proto_id(),
                    starts_at: Some(new_starts_at.to_proto()),
                    ends_at: Some(new_ends_at.to_proto()),
                    location: Some(new_location.clone()),
                    post: Some(Post {
                        visibility: Visibility::ServerPublic as i32,
                        ..Default::default()
                    }),
                    ..Default::default()
                }],
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("update_event should succeed");

        assert_eq!(updated.instances.len(), 1);
        assert_eq!(
            updated.instances[0].id,
            instance.id.to_proto_id(),
            "the existing instance row should be reused, not replaced with a new id"
        );

        let row = event_instance_row(conn, instance.id).expect("instance should still exist");
        assert_eq!(row.starts_at, new_starts_at);
        assert_eq!(row.ends_at, new_ends_at);
        assert_eq!(
            row.location,
            Some(serde_json::to_value(&new_location).unwrap())
        );
        assert!(row.updated_at.is_some());

        Ok(())
    });
}

#[test]
fn an_instance_omitted_from_the_request_is_deleted_but_its_post_survives() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_omit_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts::default());
        let (kept, _kept_post) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());
        let (removed, removed_post) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

        update_event(
            Event {
                id: event.id.to_proto_id(),
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![EventInstance {
                    id: kept.id.to_proto_id(),
                    starts_at: Some(kept.starts_at.to_proto()),
                    ends_at: Some(kept.ends_at.to_proto()),
                    post: Some(Post {
                        visibility: Visibility::ServerPublic as i32,
                        ..Default::default()
                    }),
                    ..Default::default()
                }],
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("update_event should succeed");

        assert!(
            event_instance_row(conn, kept.id).is_some(),
            "the instance present in the request should survive"
        );
        assert!(
            event_instance_row(conn, removed.id).is_none(),
            "the instance omitted from the request should be deleted"
        );
        let surviving_post = post_row(conn, removed_post.id);
        assert_eq!(
            surviving_post.id, removed_post.id,
            "the deleted instance's own Post should be left behind, not cascade-deleted"
        );

        Ok(())
    });
}

#[test]
fn an_instance_with_no_id_in_the_request_creates_a_new_instance() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_create_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts::default());
        let (existing, _existing_post) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

        let new_starts_at = whole_second_instant(50_000);
        let new_ends_at = whole_second_instant(53_600);

        let updated = update_event(
            Event {
                id: event.id.to_proto_id(),
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![
                    EventInstance {
                        id: existing.id.to_proto_id(),
                        starts_at: Some(existing.starts_at.to_proto()),
                        ends_at: Some(existing.ends_at.to_proto()),
                        post: Some(Post {
                            visibility: Visibility::ServerPublic as i32,
                            ..Default::default()
                        }),
                        ..Default::default()
                    },
                    EventInstance {
                        // No `id` -- brand new instance.
                        starts_at: Some(new_starts_at.to_proto()),
                        ends_at: Some(new_ends_at.to_proto()),
                        post: Some(Post {
                            visibility: Visibility::ServerPublic as i32,
                            ..Default::default()
                        }),
                        ..Default::default()
                    },
                ],
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("update_event should succeed");

        assert_eq!(updated.instances.len(), 2);
        let total: i64 = event_instances::table
            .filter(event_instances::event_id.eq(event.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(total, 2);

        let created_id = updated
            .instances
            .iter()
            .map(|i| i.id.to_db_id().unwrap())
            .find(|id| *id != existing.id)
            .expect("a second, newly-created instance should be present");
        let created_row = event_instance_row(conn, created_id).unwrap();
        assert_eq!(created_row.starts_at, new_starts_at);
        assert_eq!(created_row.ends_at, new_ends_at);
        assert_eq!(created_row.event_id, event.id);

        Ok(())
    });
}

/// The headline "multi-`EventInstance`-merging" behavior: a single `UpdateEvent` call that
/// simultaneously updates one instance in place, creates a brand new one, and deletes two others
/// by omitting them -- and the author's `event_instance_count` is recomputed to match the net
/// result, not incremented/decremented piecemeal.
#[test]
fn a_single_call_can_update_create_and_delete_instances_together() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_merge_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts::default());
        let (updated_instance, _) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());
        let (removed_a, _) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());
        let (removed_b, _) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

        let new_starts_at = whole_second_instant(90_000);
        let new_ends_at = whole_second_instant(93_600);

        let result = update_event(
            Event {
                id: event.id.to_proto_id(),
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![
                    EventInstance {
                        id: updated_instance.id.to_proto_id(),
                        starts_at: Some(new_starts_at.to_proto()),
                        ends_at: Some(new_ends_at.to_proto()),
                        post: Some(Post {
                            visibility: Visibility::ServerPublic as i32,
                            ..Default::default()
                        }),
                        ..Default::default()
                    },
                    EventInstance {
                        starts_at: Some(new_starts_at.to_proto()),
                        ends_at: Some(new_ends_at.to_proto()),
                        post: Some(Post {
                            visibility: Visibility::ServerPublic as i32,
                            ..Default::default()
                        }),
                        ..Default::default()
                    },
                    // `removed_a`/`removed_b` are intentionally omitted here.
                ],
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("update_event should succeed");

        assert_eq!(result.instances.len(), 2, "1 updated + 1 created");
        assert!(event_instance_row(conn, updated_instance.id).is_some());
        assert!(event_instance_row(conn, removed_a.id).is_none());
        assert!(event_instance_row(conn, removed_b.id).is_none());

        let total: i64 = event_instances::table
            .filter(event_instances::event_id.eq(event.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(total, 2, "started with 3 instances, net +1 -2 = 2");

        let author = models::get_user(author.id, conn)?;
        assert_eq!(
            author.event_instance_count, 2,
            "count should reflect the net result of the merge, not a stale running total"
        );

        Ok(())
    });
}

#[test]
fn an_instance_id_belonging_to_a_different_event_is_not_reassigned() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_crossevent_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event_a, event_a_post) = create_event(conn, &author, EventOpts::default());
        let (event_b, _event_b_post) = create_event(conn, &author, EventOpts::default());
        let (instance_b, _) =
            create_event_instance(conn, &event_b, Some(&author), EventInstanceOpts::default());

        let result = update_event(
            Event {
                id: event_a.id.to_proto_id(),
                post: Some(Post {
                    id: event_a_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![EventInstance {
                    // `instance_b`'s id, but submitted under event A.
                    id: instance_b.id.to_proto_id(),
                    starts_at: Some(instance_b.starts_at.to_proto()),
                    ends_at: Some(instance_b.ends_at.to_proto()),
                    post: Some(Post {
                        visibility: Visibility::ServerPublic as i32,
                        ..Default::default()
                    }),
                    ..Default::default()
                }],
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("update_event should succeed");

        assert_eq!(result.instances.len(), 1);
        let new_instance_id = result.instances[0].id.to_db_id().unwrap();
        assert_ne!(
            new_instance_id, instance_b.id,
            "a foreign instance id should mint a new instance, not hijack the original"
        );

        let event_a_instances: i64 = event_instances::table
            .filter(event_instances::event_id.eq(event_a.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(event_a_instances, 1);

        let untouched = event_instance_row(conn, instance_b.id)
            .expect("instance_b should be untouched, not moved or deleted");
        assert_eq!(untouched.event_id, event_b.id, "still belongs to event B");
        assert_eq!(untouched.starts_at, instance_b.starts_at);

        Ok(())
    });
}

/// Not really a "merge" case, but a sharp edge of one: an `EventInstance` entry that matches an
/// existing instance by id but omits `post` entirely resets that instance's Post visibility to
/// `PRIVATE`, since `update_event_instances` treats a missing `post` as an explicit
/// `Visibility::Private` rather than "leave the current visibility alone" (see `update_event.rs`,
/// the `unwrap_or(Visibility::Private)` on `request_instance.post.as_ref().map(|p| p.visibility())`).
#[test]
fn omitting_an_existing_instances_post_resets_its_visibility_to_private() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_visibility_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts::default());
        let (instance, instance_post) = create_event_instance(
            conn,
            &event,
            Some(&author),
            EventInstanceOpts {
                visibility: Visibility::ServerPublic,
                ..Default::default()
            },
        );
        assert_eq!(instance_post.visibility, "SERVER_PUBLIC");

        update_event(
            Event {
                id: event.id.to_proto_id(),
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![EventInstance {
                    id: instance.id.to_proto_id(),
                    starts_at: Some(instance.starts_at.to_proto()),
                    ends_at: Some(instance.ends_at.to_proto()),
                    post: None,
                    ..Default::default()
                }],
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("update_event should succeed");

        let post_after = post_row(conn, instance_post.id);
        assert_eq!(post_after.visibility, "PRIVATE");

        Ok(())
    });
}

/// The comment at `update_event.rs`'s `removed_instance_owner_ids` explains why this matters: an
/// instance's own Post can be owned by someone other than the event's author (e.g. an admin
/// editing another user's event), and deleting that instance -- via omission -- needs to refresh
/// *that* owner's `event_instance_count`, not just the acting user's.
#[test]
fn deleting_an_instance_owned_by_a_different_user_refreshes_that_users_event_instance_count() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let event_author = create_user(conn, "uet_owner_author");
        let instance_owner = create_user(conn, "uet_owner_instance");
        let admin = create_user(conn, "uet_owner_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let (event, event_post) = create_event(conn, &event_author, EventOpts::default());
        let (instance, _) = create_event_instance(
            conn,
            &event,
            Some(&instance_owner),
            EventInstanceOpts::default(),
        );

        // Simulate drift, so recomputation (rather than a coincidental correct value) is what's
        // under test -- mirrors `update_all_counts_corrects_manually_drifted_counts` in
        // `user_counts_tests`.
        diesel::update(users::table.filter(users::id.eq(instance_owner.id)))
            .set(users::event_instance_count.eq(5))
            .execute(conn)
            .unwrap();

        update_event(
            Event {
                id: event.id.to_proto_id(),
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![], // omits `instance` -> deleted
                ..Default::default()
            },
            &admin,
            conn,
        )
        .expect("admin update_event should succeed");

        assert!(event_instance_row(conn, instance.id).is_none());
        let instance_owner = models::get_user(instance_owner.id, conn)?;
        assert_eq!(
            instance_owner.event_instance_count, 0,
            "should be recomputed to the true count, not left at the drifted value"
        );

        Ok(())
    });
}
