//! Specs for `delete_user`: who's allowed to call it, and that it actually cleans up everything
//! the user owned -- Events (via `delete_event`), Posts/Replies (via `delete_post`), Media
//! (via `delete_media`, including its MinIO objects), and EventSyncSources/EventSyncDestinations
//! -- before removing the `users` row itself. Needs a real MinIO connection for the Media leg --
//! see `factories::test_bucket`.

use diesel::prelude::*;
use tonic::Code;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::delete_user;
use crate::schema::{
    event_instances, event_sync_destinations, event_sync_sources, events, media, users,
};
use crate::tests::factories::*;

fn unique_path(name: &str) -> String {
    format!("test/delete_user_spec/{}-{}", name, uuid::Uuid::new_v4())
}

#[test]
fn self_delete_removes_the_user() {
    let tb = test_bucket();
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "dut_self");

        tb.block_on(delete_user(
            user.to_proto(&None, &None, None, None),
            &user,
            conn,
            &tb.bucket,
        ))
        .expect("self delete should succeed");

        let remaining: i64 = users::table
            .filter(users::id.eq(user.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn delete_rejects_non_admin_non_self() {
    let tb = test_bucket();
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let target = create_user(conn, "dut_target");
        let other = create_user(conn, "dut_other");

        let err = tb
            .block_on(delete_user(
                target.to_proto(&None, &None, None, None),
                &other,
                conn,
                &tb.bucket,
            ))
            .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_ADMIN_required");

        let remaining: i64 = users::table
            .filter(users::id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 1, "target should survive a rejected delete");

        Ok(())
    });
}

#[test]
fn admin_can_delete_another_user() {
    let tb = test_bucket();
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let target = create_user(conn, "dut_admin_target");
        let admin = create_user(conn, "dut_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        tb.block_on(delete_user(
            target.to_proto(&None, &None, None, None),
            &admin,
            conn,
            &tb.bucket,
        ))
        .expect("admin delete should succeed");

        let remaining: i64 = users::table
            .filter(users::id.eq(target.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn delete_cascades_events_posts_media_and_sync_config() {
    let tb = test_bucket();
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "dut_cascade");

        // A top-level Post and a Reply to it -- both PostContext::Post/Reply, so DeletePost
        // should soft-delete (scrub content, null user_id) rather than remove the row.
        let post = create_post(conn, Some(&user), PostOpts::default());
        let reply = create_post(
            conn,
            Some(&user),
            PostOpts {
                context: PostContext::Reply,
                parent_post_id: Some(post.id),
                title: None,
                content: Some("A reply".to_string()),
                ..Default::default()
            },
        );

        // An Event (with one EventInstance) -- DeleteEvent only removes the `events`/
        // `event_instances` rows, not their container Posts (PostContext::Event/EventInstance),
        // so those survive as orphaned rows once the user's own row (and thus the `ON DELETE SET
        // NULL` FK) is gone.
        let (event, event_post) = create_event(conn, &user, EventOpts::default());
        let (instance, instance_post) =
            create_event_instance(conn, &event, Some(&user), EventInstanceOpts::default());

        // Media -- DeleteMedia should hard-delete the row and the backing MinIO object.
        let media_path = unique_path("cascade");
        tb.block_on(tb.bucket.put_object(&media_path, b"test-bytes"))
            .expect("failed to seed test MinIO object");
        let user_media = create_media(conn, Some(&user), &media_path);

        // An EventSyncSource/EventSyncDestination the user configured.
        let sync_source =
            create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");
        let sync_destination = create_event_sync_destination_row(conn, &user, "test-page-id");

        tb.block_on(delete_user(
            user.to_proto(&None, &None, None, None),
            &user,
            conn,
            &tb.bucket,
        ))
        .expect("self delete should succeed");

        // The user itself is gone.
        let remaining_users: i64 = users::table
            .filter(users::id.eq(user.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_users, 0);

        // Post/Reply were soft-deleted via DeletePost, not removed outright.
        let post_after = models::get_post(post.id, conn).unwrap();
        assert_eq!(post_after.user_id, None);
        assert_eq!(post_after.title, None);
        assert_eq!(post_after.content, None);
        let reply_after = models::get_post(reply.id, conn).unwrap();
        assert_eq!(reply_after.user_id, None);
        assert_eq!(reply_after.content, None);

        // The Event (and its Instance) were removed via DeleteEvent.
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
        assert_eq!(remaining_instances, 0);

        // DeleteEvent doesn't scrub the Event/EventInstance's own container Posts -- they survive
        // as orphaned rows (ownership severed only by the `users` row's own FK cascade), unlike
        // Post/Reply above. Documented here since it's the one asymmetry in the cascade.
        let event_post_after = models::get_post(event_post.id, conn).unwrap();
        assert_eq!(event_post_after.user_id, None);
        assert!(event_post_after.title.is_some());
        let instance_post_after = models::get_post(instance_post.id, conn).unwrap();
        assert_eq!(instance_post_after.user_id, None);

        // Media was hard-deleted, and its MinIO object cleaned up.
        let remaining_media: i64 = media::table
            .filter(media::id.eq(user_media.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_media, 0);
        assert!(!tb.object_exists(&media_path));

        // EventSyncSource/EventSyncDestination were removed.
        let remaining_sources: i64 = event_sync_sources::table
            .filter(event_sync_sources::id.eq(sync_source.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_sources, 0);
        let remaining_destinations: i64 = event_sync_destinations::table
            .filter(event_sync_destinations::id.eq(sync_destination.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_destinations, 0);

        Ok(())
    });
}
