//! Specs for `update_event`'s instance-merging behavior (`update_occasions`, in
//! `rpcs/events/update_event.rs`): given a request's `instances` list, each entry is matched
//! against the event's existing instances by `post.id` (an `Occasion`'s identity *is* its own
//! Post's ID -- there's no separate surrogate ID), then either updated in place, created fresh, or
//! (if an existing instance's `post.id` is missing from the request) deleted. These specs exercise
//! that matching logic directly --
//! `create_event_sets_event_count_once_and_occasion_count_per_instance` in
//! `user_counts_tests` only covers the pure-create path (`CreateEvent`), not `UpdateEvent`'s
//! three-way merge.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use diesel::prelude::*;
use tonic::Status;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::update_event;
use crate::schema::{occasions, posts, users};
use crate::tests::factories::*;

/// A `SystemTime` truncated to whole seconds, `offset_secs` in the future. `Timestamp::to_proto`
/// (see `time_marshaling.rs`) always zeroes out sub-second precision, so any `SystemTime` built
/// from sub-second-precision data (e.g. `SystemTime::now()` directly) would silently lose that
/// precision on its way through a request -- comparing against it post-update would then require
/// truncating the expected value too. Building already-whole-second timestamps up front keeps the
/// round trip lossless and the assertions exact.
fn whole_second_instant(offset_secs: u64) -> SystemTime {
    let now_secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    UNIX_EPOCH + Duration::from_secs(now_secs + offset_secs)
}

fn occasion_row(
    conn: &mut crate::db_connection::PgPooledConnection,
    post_id: i64,
) -> Option<models::Occasion> {
    occasions::table
        .select(models::OCCASION_COLUMNS)
        .filter(occasions::post_id.eq(post_id))
        .first::<models::Occasion>(conn)
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
/// what these specs are about -- so assertions here go against `occasions`/`posts` rows
/// directly (matching `delete_event_tests`' convention), and only use the RPC's return value for
/// instance-count/id checks it's convenient for.
#[test]
fn updating_an_existing_instance_in_place_preserves_its_id_and_persists_changed_fields() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_inplace_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (instance, _instance_post) = create_occasion(
            conn,
            &event,
            Some(&author),
            OccasionOpts {
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
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![Occasion {
                    starts_at: Some(new_starts_at.to_proto()),
                    ends_at: Some(new_ends_at.to_proto()),
                    location: Some(new_location.clone()),
                    post: Some(Post {
                        id: instance.post_id.to_proto_id(),
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
            updated.instances[0].post.as_ref().unwrap().id,
            instance.post_id.to_proto_id(),
            "the existing instance row should be reused, not replaced with a new id"
        );

        let row =
            occasion_row(conn, instance.post_id).expect("instance should still exist");
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
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (kept, _kept_post) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());
        let (removed, removed_post) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());

        update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![Occasion {
                    starts_at: Some(kept.starts_at.to_proto()),
                    ends_at: Some(kept.ends_at.to_proto()),
                    post: Some(Post {
                        id: kept.post_id.to_proto_id(),
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
            occasion_row(conn, kept.post_id).is_some(),
            "the instance present in the request should survive"
        );
        assert!(
            occasion_row(conn, removed.post_id).is_none(),
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
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (existing, _existing_post) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());

        let new_starts_at = whole_second_instant(50_000);
        let new_ends_at = whole_second_instant(53_600);

        let updated = update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![
                    Occasion {
                        starts_at: Some(existing.starts_at.to_proto()),
                        ends_at: Some(existing.ends_at.to_proto()),
                        post: Some(Post {
                            id: existing.post_id.to_proto_id(),
                            visibility: Visibility::ServerPublic as i32,
                            ..Default::default()
                        }),
                        ..Default::default()
                    },
                    Occasion {
                        // No `post` (or a `post` with no `id`) -- brand new instance.
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
        let total: i64 = occasions::table
            .filter(occasions::event_id.eq(event.post_id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(total, 2);

        let created_id = updated
            .instances
            .iter()
            .map(|i| i.post.as_ref().unwrap().id.to_db_id().unwrap())
            .find(|id| *id != existing.post_id)
            .expect("a second, newly-created instance should be present");
        let created_row = occasion_row(conn, created_id).unwrap();
        assert_eq!(created_row.starts_at, new_starts_at);
        assert_eq!(created_row.ends_at, new_ends_at);
        assert_eq!(created_row.event_id, event.post_id);

        Ok(())
    });
}

/// The headline "multi-`Occasion`-merging" behavior: a single `UpdateEvent` call that
/// simultaneously updates one instance in place, creates a brand new one, and deletes two others
/// by omitting them -- and the author's `occasion_count` is recomputed to match the net
/// result, not incremented/decremented piecemeal.
#[test]
fn a_single_call_can_update_create_and_delete_instances_together() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_merge_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (updated_instance, _) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());
        let (removed_a, _) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());
        let (removed_b, _) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());

        let new_starts_at = whole_second_instant(90_000);
        let new_ends_at = whole_second_instant(93_600);

        let result = update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![
                    Occasion {
                        starts_at: Some(new_starts_at.to_proto()),
                        ends_at: Some(new_ends_at.to_proto()),
                        post: Some(Post {
                            id: updated_instance.post_id.to_proto_id(),
                            visibility: Visibility::ServerPublic as i32,
                            ..Default::default()
                        }),
                        ..Default::default()
                    },
                    Occasion {
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
        assert!(occasion_row(conn, updated_instance.post_id).is_some());
        assert!(occasion_row(conn, removed_a.post_id).is_none());
        assert!(occasion_row(conn, removed_b.post_id).is_none());

        let total: i64 = occasions::table
            .filter(occasions::event_id.eq(event.post_id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(total, 2, "started with 3 instances, net +1 -2 = 2");

        let author = models::get_user(author.id, conn)?;
        assert_eq!(
            author.occasion_count, 2,
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
        let (event_a, event_a_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (event_b, _event_b_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (instance_b, _) =
            create_occasion(conn, &event_b, Some(&author), OccasionOpts::default());

        let result = update_event(
            Event {
                post: Some(Post {
                    id: event_a_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![Occasion {
                    // `instance_b`'s post id, but submitted under event A.
                    starts_at: Some(instance_b.starts_at.to_proto()),
                    ends_at: Some(instance_b.ends_at.to_proto()),
                    post: Some(Post {
                        id: instance_b.post_id.to_proto_id(),
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
        let new_instance_id = result.instances[0]
            .post
            .as_ref()
            .unwrap()
            .id
            .to_db_id()
            .unwrap();
        assert_ne!(
            new_instance_id, instance_b.post_id,
            "a foreign instance id should mint a new instance, not hijack the original"
        );

        let event_a_instances: i64 = occasions::table
            .filter(occasions::event_id.eq(event_a.post_id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(event_a_instances, 1);

        let untouched = occasion_row(conn, instance_b.post_id)
            .expect("instance_b should be untouched, not moved or deleted");
        assert_eq!(
            untouched.event_id, event_b.post_id,
            "still belongs to event B"
        );
        assert_eq!(untouched.starts_at, instance_b.starts_at);

        Ok(())
    });
}

/// Resetting an instance's Post to `PRIVATE` requires explicitly sending `visibility: PRIVATE` in
/// its `post` -- omitting `post` entirely can no longer double as "make this private" the way it
/// used to (see `update_occasions_impl`'s own doc comment): since an `Occasion`'s
/// identity *is* its `post.id`, an update entry with no `post` has nothing to match against, and
/// would (dangerously) be treated as a brand new instance rather than updating the existing one --
/// see `an_instance_update_with_no_post_creates_a_new_instance_instead_of_matching_the_existing_one`
/// below for that sharp edge.
#[test]
fn explicitly_setting_an_existing_instances_post_visibility_to_private_persists_it() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_visibility_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (instance, instance_post) = create_occasion(
            conn,
            &event,
            Some(&author),
            OccasionOpts {
                visibility: Visibility::ServerPublic,
                ..Default::default()
            },
        );
        assert_eq!(instance_post.visibility, "SERVER_PUBLIC");

        update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![Occasion {
                    starts_at: Some(instance.starts_at.to_proto()),
                    ends_at: Some(instance.ends_at.to_proto()),
                    post: Some(Post {
                        id: instance_post.id.to_proto_id(),
                        visibility: Visibility::Private as i32,
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

        let post_after = post_row(conn, instance_post.id);
        assert_eq!(post_after.visibility, "PRIVATE");

        Ok(())
    });
}

/// The old "omit `post`" trick no longer identifies an existing instance -- since identity moved
/// to `post.id`, an update entry with no `post` at all is indistinguishable from a brand new
/// instance, and `update_event`'s create-before-delete ordering (see its own doc comment) means it
/// gets created rather than silently dropped or matched to the original.
#[test]
fn an_instance_update_with_no_post_creates_a_new_instance_instead_of_matching_the_existing_one() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_nopost_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (instance, instance_post) = create_occasion(
            conn,
            &event,
            Some(&author),
            OccasionOpts {
                visibility: Visibility::ServerPublic,
                ..Default::default()
            },
        );

        let updated = update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![Occasion {
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

        assert_eq!(
            updated.instances.len(),
            1,
            "the original instance didn't match anything (no post.id) so it was deleted; the \
             post-less entry created a new one in its place"
        );
        let new_post = updated.instances[0]
            .post
            .as_ref()
            .expect("a post always comes back on read, even for a no-post-override instance");
        assert_ne!(
            new_post.id,
            instance_post.id.to_proto_id(),
            "this is a brand new instance/post, not the original one reset in place"
        );
        assert_eq!(
            new_post.visibility(),
            Visibility::GlobalPublic,
            "a post-less create defaults to GLOBAL_PUBLIC, not PRIVATE -- proving the old \
             \"omit post to reset to private\" trick no longer applies"
        );
        assert!(
            occasion_row(conn, instance.post_id).is_none(),
            "the original instance is gone -- it didn't match anything in the request"
        );
        let original_post_after = post_row(conn, instance_post.id);
        assert_eq!(
            original_post_after.visibility, "SERVER_PUBLIC",
            "the original instance's own Post is untouched (not deleted, not reset to PRIVATE)"
        );

        Ok(())
    });
}

/// The comment at `update_event.rs`'s `removed_instance_owner_ids` explains why this matters: an
/// instance's own Post can be owned by someone other than the event's author (e.g. an admin
/// editing another user's event), and deleting that instance -- via omission -- needs to refresh
/// *that* owner's `occasion_count`, not just the acting user's. A second, kept instance
/// (owned by `event_author`) keeps the event from being left with zero instances, which is its
/// own separate edge case -- see `deleting_the_only_instance_leaves_the_event_unretrievable`.
#[test]
fn deleting_an_instance_owned_by_a_different_user_refreshes_that_users_occasion_count() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let event_author = create_user(conn, "uet_owner_author");
        let instance_owner = create_user(conn, "uet_owner_instance");
        let admin = create_user(conn, "uet_owner_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let (event, event_post) = create_event(conn, &event_author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (kept, _) = create_occasion(
            conn,
            &event,
            Some(&event_author),
            OccasionOpts::default(),
        );
        let (removed, _) = create_occasion(
            conn,
            &event,
            Some(&instance_owner),
            OccasionOpts::default(),
        );

        // Simulate drift, so recomputation (rather than a coincidental correct value) is what's
        // under test -- mirrors `update_all_counts_corrects_manually_drifted_counts` in
        // `user_counts_tests`.
        diesel::update(users::table.filter(users::id.eq(instance_owner.id)))
            .set(users::occasion_count.eq(5))
            .execute(conn)
            .unwrap();

        update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    // `update_post` unconditionally overwrites moderation with this field
                    // whenever the caller is an admin/moderator (see `update_post.rs`'s
                    // `if admin || moderator { existing_post.moderation = ... }`), regardless of
                    // whether it's otherwise a moderator-accessible value -- an admin submitting
                    // the proto default here would flip the post to `MODERATION_UNKNOWN` and make
                    // it invisible to `get_events`' `PASSING_MODERATIONS` filter.
                    moderation: Moderation::Unmoderated as i32,
                    ..Default::default()
                }),
                instances: vec![Occasion {
                    starts_at: Some(kept.starts_at.to_proto()),
                    ends_at: Some(kept.ends_at.to_proto()),
                    post: Some(Post {
                        id: kept.post_id.to_proto_id(),
                        visibility: Visibility::ServerPublic as i32,
                        ..Default::default()
                    }),
                    ..Default::default()
                }], // omits `removed` -> deleted
                ..Default::default()
            },
            &admin,
            conn,
        )
        .expect("admin update_event should succeed");

        assert!(occasion_row(conn, removed.post_id).is_none());
        let instance_owner = models::get_user(instance_owner.id, conn)?;
        assert_eq!(
            instance_owner.occasion_count, 0,
            "should be recomputed to the true count, not left at the drifted value"
        );

        Ok(())
    });
}

/// A sharp edge of the merge behavior: `get_events`' visibility query (`query_visible_events!` in
/// `get_events.rs`) starts from an `INNER JOIN` on `occasions`, so an event with zero
/// instances simply cannot be selected by it. `update_event` re-reads the event via that same
/// query as its last step (to build the response), so omitting an event's only instance -- which
/// the merge itself handles fine, deleting the row and refreshing counts -- makes the overall RPC
/// call fail with `event_not_found`, even though the event (and its container Post) still exist.
#[test]
fn deleting_the_only_instance_leaves_the_event_unretrievable_by_get_events() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let author = create_user(conn, "uet_lastinstance_author");
        let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
        let (event, event_post) = create_event(conn, &author, EventOpts {
                default_instance: None,
                ..Default::default()
            });
        let (only_instance, _) =
            create_occasion(conn, &event, Some(&author), OccasionOpts::default());

        let err = update_event(
            Event {
                post: Some(Post {
                    id: event_post.id.to_proto_id(),
                    visibility: Visibility::ServerPublic as i32,
                    ..Default::default()
                }),
                instances: vec![], // omits `only_instance` -> deleted
                ..Default::default()
            },
            &author,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.message(), "event_not_found");

        // The merge itself still committed, despite the RPC returning an error.
        assert!(occasion_row(conn, only_instance.post_id).is_none());
        let surviving_event: i64 = crate::schema::events::table
            .filter(crate::schema::events::post_id.eq(event.post_id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(surviving_event, 1, "the event row itself is not deleted");
        let surviving_post = post_row(conn, event_post.id);
        assert_eq!(surviving_post.id, event_post.id);

        Ok(())
    });
}
