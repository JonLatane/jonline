//! Specs for the standalone RPCs `update_event` was split into (see `rpcs/events/`):
//! `update_event_details`, `create_new_event_instances`, `update_event_instances`, and
//! `delete_removed_event_instances`. `update_event_tests` already exercises the combined
//! behavior (via `update_event`, which now just drives these four in sequence); these specs
//! instead call each one directly, covering:
//! - each RPC only touches the slice of an `Event` its name promises (not, e.g., `UpdateEventInstances`
//!   accidentally creating an instance it didn't find a match for).
//! - the authorization check every instance-mutating RPC now needs, now that they're reachable on
//!   their own instead of only as a side effect of `update_event`'s `UpdatePost` call on the
//!   event's own Post (see `event_permissions.rs`'s doc comment for why this wasn't needed before).

use diesel::prelude::*;
use tonic::Status;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::{
    create_new_event_instances, delete_removed_event_instances, update_event_details,
    update_event_instances,
};
use crate::schema::{event_instances, posts};
use crate::tests::factories::*;

fn event_instance_row(
    conn: &mut crate::db_connection::PgPooledConnection,
    id: i64,
) -> Option<models::EventInstance> {
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

mod update_event_details_specs {
    use super::*;

    #[test]
    fn updates_event_info_and_its_own_post_without_touching_instances() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "uedt_author");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let (event, event_post) = create_event(conn, &author, EventOpts::default());
            let (instance, _) = get_event_instances(conn, event.id);

            let updated = update_event_details(
                Event {
                    id: event.id.to_proto_id(),
                    post: Some(Post {
                        id: event_post.id.to_proto_id(),
                        title: Some("New Title".to_string()),
                        visibility: Visibility::ServerPublic as i32,
                        ..Default::default()
                    }),
                    info: Some(EventInfo {
                        allows_rsvps: Some(true),
                        ..Default::default()
                    }),
                    ..Default::default()
                },
                &author,
                conn,
            )
            .expect("update_event_details should succeed");

            assert_eq!(
                post_row(conn, event_post.id).title,
                Some("New Title".to_string())
            );
            assert_eq!(updated.instances.len(), 1);
            assert_eq!(
                updated.instances[0].id,
                instance.id.to_proto_id(),
                "the untouched instance should still be present"
            );

            Ok(())
        });
    }

    #[test]
    fn requires_an_associated_post() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "uedt_nopost_author");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let (event, _event_post) = create_event(conn, &author, EventOpts::default());

            let err = update_event_details(
                Event {
                    id: event.id.to_proto_id(),
                    post: None,
                    ..Default::default()
                },
                &author,
                conn,
            )
            .unwrap_err();
            assert_eq!(err.message(), "event must contain associated post");

            Ok(())
        });
    }

    #[test]
    fn a_non_owner_without_moderation_permissions_cannot_update_event_details() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "uedt_owner");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let stranger = create_user(conn, "uedt_stranger");
            let (event, event_post) = create_event(conn, &author, EventOpts::default());

            let err = update_event_details(
                Event {
                    id: event.id.to_proto_id(),
                    post: Some(Post {
                        id: event_post.id.to_proto_id(),
                        title: Some("Hijacked".to_string()),
                        visibility: Visibility::ServerPublic as i32,
                        ..Default::default()
                    }),
                    ..Default::default()
                },
                &stranger,
                conn,
            )
            .unwrap_err();
            assert_ne!(err.message(), "");
            assert_eq!(
                post_row(conn, event_post.id).title,
                Some("Test Post".to_string()),
                "the post should be untouched"
            );

            Ok(())
        });
    }
}

mod create_new_event_instances_specs {
    use super::*;

    #[test]
    fn creates_only_the_instances_that_dont_already_exist_on_the_event() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "cnei_author");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let (event, event_post) = create_event(conn, &author, EventOpts {
                    default_instance: None,
                    ..Default::default()
                });
            let (existing, _) =
                create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

            let new_starts_at = whole_second_instant(3600);
            let new_ends_at = whole_second_instant(7200);

            let updated = create_new_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![
                        // Matches `existing` -- should be ignored (not duplicated).
                        EventInstance {
                            id: existing.id.to_proto_id(),
                            starts_at: Some(whole_second_instant(1).to_proto()),
                            ends_at: Some(whole_second_instant(2).to_proto()),
                            ..Default::default()
                        },
                        // No id -- should be created.
                        EventInstance {
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
            .expect("create_new_event_instances should succeed");

            assert_eq!(updated.instances.len(), 2, "1 pre-existing + 1 created");
            let total: i64 = event_instances::table
                .filter(event_instances::event_id.eq(event.id))
                .count()
                .get_result(conn)
                .unwrap();
            assert_eq!(total, 2);

            let existing_row = event_instance_row(conn, existing.id).unwrap();
            assert_eq!(
                existing_row.starts_at, existing.starts_at,
                "the already-existing instance should be untouched, not updated to the request's values"
            );

            let created_id = updated
                .instances
                .iter()
                .map(|i| i.id.to_db_id().unwrap())
                .find(|id| *id != existing.id)
                .expect("the newly-created instance should be present");
            let created_row = event_instance_row(conn, created_id).unwrap();
            assert_eq!(created_row.starts_at, new_starts_at);
            assert_eq!(created_row.ends_at, new_ends_at);

            let author = models::get_user(author.id, conn)?;
            assert_eq!(author.event_instance_count, 2);

            let _ = event_post;
            Ok(())
        });
    }

    #[test]
    fn a_non_owner_without_moderation_permissions_cannot_create_instances() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "cnei_owner");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let stranger = create_user(conn, "cnei_stranger");
            let (event, _) = create_event(
                conn,
                &author,
                EventOpts {
                    default_instance: None,
                    ..Default::default()
                },
            );

            let err = create_new_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![EventInstance {
                        starts_at: Some(whole_second_instant(3600).to_proto()),
                        ends_at: Some(whole_second_instant(7200).to_proto()),
                        ..Default::default()
                    }],
                    ..Default::default()
                },
                &stranger,
                conn,
            )
            .unwrap_err();
            assert_ne!(err.message(), "");

            let total: i64 = event_instances::table
                .filter(event_instances::event_id.eq(event.id))
                .count()
                .get_result(conn)
                .unwrap();
            assert_eq!(total, 0, "no instance should have been created");

            Ok(())
        });
    }
}

mod update_event_instances_specs {
    use super::*;

    #[test]
    fn updates_matched_instances_and_ignores_unmatched_ones() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "uei_author");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let (event, _event_post) = create_event(
                conn,
                &author,
                EventOpts {
                    default_instance: None,
                    ..Default::default()
                },
            );
            let (instance, _) = create_event_instance(
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

            update_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![
                        EventInstance {
                            id: instance.id.to_proto_id(),
                            starts_at: Some(new_starts_at.to_proto()),
                            ends_at: Some(new_ends_at.to_proto()),
                            post: Some(Post {
                                visibility: Visibility::ServerPublic as i32,
                                ..Default::default()
                            }),
                            ..Default::default()
                        },
                        // No id -- can't match anything, must be ignored (not created).
                        EventInstance {
                            starts_at: Some(whole_second_instant(1).to_proto()),
                            ends_at: Some(whole_second_instant(2).to_proto()),
                            ..Default::default()
                        },
                    ],
                    ..Default::default()
                },
                &author,
                conn,
            )
            .expect("update_event_instances should succeed");

            let row = event_instance_row(conn, instance.id).unwrap();
            assert_eq!(row.starts_at, new_starts_at);
            assert_eq!(row.ends_at, new_ends_at);

            let total: i64 = event_instances::table
                .filter(event_instances::event_id.eq(event.id))
                .count()
                .get_result(conn)
                .unwrap();
            assert_eq!(
                total, 1,
                "the id-less entry should be ignored, not create a second instance"
            );

            Ok(())
        });
    }

    #[test]
    fn a_non_owner_without_moderation_permissions_cannot_update_instances() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "uei_owner");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let stranger = create_user(conn, "uei_stranger");
            let (event, _) = create_event(conn, &author, EventOpts::default());
            let (instance, _) = get_event_instances(conn, event.id);

            let err = update_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![EventInstance {
                        id: instance.id.to_proto_id(),
                        starts_at: Some(whole_second_instant(10_000).to_proto()),
                        ends_at: Some(whole_second_instant(20_000).to_proto()),
                        ..Default::default()
                    }],
                    ..Default::default()
                },
                &stranger,
                conn,
            )
            .unwrap_err();
            assert_ne!(err.message(), "");

            let row = event_instance_row(conn, instance.id).unwrap();
            assert_eq!(
                row.starts_at, instance.starts_at,
                "the instance should be untouched"
            );

            Ok(())
        });
    }
}

mod delete_removed_event_instances_specs {
    use super::*;

    #[test]
    fn deletes_instances_absent_from_the_request_and_keeps_the_rest() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "drei_author");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let (event, _event_post) = create_event(
                conn,
                &author,
                EventOpts {
                    default_instance: None,
                    ..Default::default()
                },
            );
            let (kept, _) =
                create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());
            let (removed, removed_post) =
                create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

            delete_removed_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![EventInstance {
                        id: kept.id.to_proto_id(),
                        ..Default::default()
                    }],
                    ..Default::default()
                },
                &author,
                conn,
            )
            .expect("delete_removed_event_instances should succeed");

            assert!(event_instance_row(conn, kept.id).is_some());
            assert!(event_instance_row(conn, removed.id).is_none());
            let surviving_post = post_row(conn, removed_post.id);
            assert_eq!(
                surviving_post.id, removed_post.id,
                "the deleted instance's own Post should survive"
            );

            Ok(())
        });
    }

    #[test]
    fn a_non_owner_without_moderation_permissions_cannot_delete_instances() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "drei_owner");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let stranger = create_user(conn, "drei_stranger");
            let (event, _) = create_event(
                conn,
                &author,
                EventOpts {
                    default_instance: None,
                    ..Default::default()
                },
            );
            let (only_instance, _) =
                create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

            let err = delete_removed_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![], // would delete `only_instance`, if it were authorized
                    ..Default::default()
                },
                &stranger,
                conn,
            )
            .unwrap_err();
            assert_ne!(err.message(), "");

            assert!(
                event_instance_row(conn, only_instance.id).is_some(),
                "the instance should not have been deleted"
            );

            Ok(())
        });
    }

    #[test]
    fn an_admin_can_delete_instances_on_someone_elses_event() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let author = create_user(conn, "drei_admin_author");
            let author = grant_permissions(conn, &author, vec![Permission::PublishEventsLocally]);
            let admin = create_user(conn, "drei_admin");
            let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);
            let (event, _) = create_event(
                conn,
                &author,
                EventOpts {
                    default_instance: None,
                    ..Default::default()
                },
            );
            let (only_instance, _) =
                create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

            delete_removed_event_instances(
                Event {
                    id: event.id.to_proto_id(),
                    instances: vec![],
                    ..Default::default()
                },
                &admin,
                conn,
            )
            .unwrap_err(); // event becomes unretrievable (no instances left), same as update_event's
            // own `deleting_the_only_instance_leaves_the_event_unretrievable_by_get_events`

            assert!(
                event_instance_row(conn, only_instance.id).is_none(),
                "the merge itself should still have committed"
            );

            let author = models::get_user(author.id, conn)?;
            assert_eq!(author.event_instance_count, 0);

            Ok(())
        });
    }
}

/// `EventOpts::default()` seeds exactly one instance -- these specs need its id to build requests
/// against, but not the ceremony of `EventOpts { default_instance: None, .. }` +
/// `create_event_instance` everywhere a single default instance is all that's needed.
fn get_event_instances(
    conn: &mut crate::db_connection::PgPooledConnection,
    event_id: i64,
) -> (models::EventInstance, models::Post) {
    let (instance, post, _author) = models::get_event_instances(event_id, &None, conn)
        .unwrap()
        .remove(0);
    (instance, post)
}

fn whole_second_instant(offset_secs: u64) -> std::time::SystemTime {
    use std::time::{Duration, UNIX_EPOCH};
    let now_secs = std::time::SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs();
    UNIX_EPOCH + Duration::from_secs(now_secs + offset_secs)
}
