//! Specs for `delete_event`: ownership/permission checks, and what it actually removes.
//! `delete_event_clears_event_and_event_instance_counts` in `user_counts_tests` already covers
//! the author's own counts; this file covers permissions plus the actual row-level effect: the
//! `events` row (and its `event_instances`, via `ON DELETE CASCADE`) are removed outright, but
//! the container `Post`(s) are left behind untouched (see `delete_user_tests`' cascade spec for
//! why that matters for `DeleteUser`).

use diesel::prelude::*;
use tonic::Code;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::delete_event;
use crate::schema::{event_instances, events};
use crate::tests::factories::*;

#[test]
fn self_delete_removes_the_event_and_instances_but_not_the_posts() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "det_self");
        let (event, event_post) = create_event(
            conn,
            &author,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, instance_post) =
            create_event_instance(conn, &event, Some(&author), EventInstanceOpts::default());

        delete_event(
            Event {
                id: event.id.to_proto_id(),
                ..Default::default()
            },
            &author,
            conn,
        )
        .expect("self delete should succeed");

        let remaining_events: i64 = events::table
            .filter(events::id.eq(event.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_events, 0);
        let remaining_instances: i64 = event_instances::table
            .filter(event_instances::id.eq(instance.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_instances, 0, "instances cascade with their event");

        // The container Posts are untouched -- delete_event doesn't scrub them.
        let event_post_after = models::get_post(event_post.id, conn).unwrap();
        assert_eq!(event_post_after.user_id, Some(author.id));
        assert!(event_post_after.title.is_some());
        let instance_post_after = models::get_post(instance_post.id, conn).unwrap();
        assert_eq!(instance_post_after.user_id, Some(author.id));

        Ok(())
    });
}

#[test]
fn delete_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "det_owner");
        let (event, _post) = create_event(conn, &author, EventOpts::default());
        let other = create_user(conn, "det_other");

        let err = delete_event(
            Event {
                id: event.id.to_proto_id(),
                ..Default::default()
            },
            &other,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::PermissionDenied);
        assert_eq!(err.message(), "permission_denied");

        let remaining: i64 = events::table
            .filter(events::id.eq(event.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 1, "event should survive a rejected delete");

        Ok(())
    });
}

#[test]
fn admin_can_delete_another_users_event() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let author = create_user(conn, "det_admin_author");
        let (event, _post) = create_event(conn, &author, EventOpts::default());
        let admin = create_user(conn, "det_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        delete_event(
            Event {
                id: event.id.to_proto_id(),
                ..Default::default()
            },
            &admin,
            conn,
        )
        .expect("admin delete should succeed");

        let remaining: i64 = events::table
            .filter(events::id.eq(event.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}
