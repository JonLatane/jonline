//! Specs for `SyncPost`/`DeletePostSyncDestination` -- mirrors `sync_destination_rpc_tests`'
//! `sync_event_instance`/`delete_event_instance_sync_destination` coverage, but for Posts (gated
//! on `SyncPostsToFacebook` instead of `SyncEventsToFacebook`). Facebook Graph API interaction
//! correctness itself is covered by `facebook_sync_tests`; these specs focus on permissions,
//! ownership, and validation.

use diesel::Connection;
use tonic::Code;

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::{delete_post_sync_destination, sync_post};
use crate::tests::factories::*;

#[test]
fn sync_post_requires_sync_posts_to_facebook_permission() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "pst_sync_noperm");
        let destination = create_sync_destination_row(conn, &owner, "123");
        let post = create_post(conn, Some(&owner), PostOpts::default());

        let err = sync_post(
            SyncPostRequest {
                post_id: post.id.to_proto_id(),
                sync_destination_id: destination.id.to_proto_id(),
            },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNC_POSTS_TO_FACEBOOK_required");

        Ok(())
    });
}

#[test]
fn sync_post_rejects_non_owner_non_admin_of_the_destination() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "pst_sync_owner");
        let destination = create_sync_destination_row(conn, &owner, "123");
        let post = create_post(conn, Some(&owner), PostOpts::default());

        let other = create_user(conn, "pst_sync_other");
        let other = grant_permissions(conn, &other, vec![Permission::SyncPostsToFacebook]);

        let err = sync_post(
            SyncPostRequest {
                post_id: post.id.to_proto_id(),
                sync_destination_id: destination.id.to_proto_id(),
            },
            &other,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_ADMIN_required");

        Ok(())
    });
}

#[test]
fn sync_post_fails_for_unknown_post() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "pst_sync_nopost");
        let owner = grant_permissions(conn, &owner, vec![Permission::SyncPostsToFacebook]);
        let destination = create_sync_destination_row(conn, &owner, "123");

        let err = sync_post(
            SyncPostRequest {
                post_id: 999_999_i64.to_proto_id(),
                sync_destination_id: destination.id.to_proto_id(),
            },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::NotFound);

        Ok(())
    });
}

#[test]
fn delete_post_sync_destination_requires_sync_posts_to_facebook_permission() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "pst_delete_noperm");
        let destination = create_sync_destination_row(conn, &owner, "123");
        let post = create_post(conn, Some(&owner), PostOpts::default());
        create_post_sync_destination_row(conn, &post, &destination);

        let err = delete_post_sync_destination(
            DeletePostSyncDestinationRequest {
                post_id: post.id.to_proto_id(),
                sync_destination_id: destination.id.to_proto_id(),
            },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNC_POSTS_TO_FACEBOOK_required");

        Ok(())
    });
}

#[test]
fn delete_post_sync_destination_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "pst_delete_owner");
        let destination = create_sync_destination_row(conn, &owner, "123");
        let post = create_post(conn, Some(&owner), PostOpts::default());
        create_post_sync_destination_row(conn, &post, &destination);

        let other = create_user(conn, "pst_delete_other");
        let other = grant_permissions(conn, &other, vec![Permission::SyncPostsToFacebook]);

        let err = delete_post_sync_destination(
            DeletePostSyncDestinationRequest {
                post_id: post.id.to_proto_id(),
                sync_destination_id: destination.id.to_proto_id(),
            },
            &other,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_ADMIN_required");

        Ok(())
    });
}

#[test]
fn delete_post_sync_destination_removes_the_join_row() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "pst_delete_ok");
        let owner = grant_permissions(conn, &owner, vec![Permission::SyncPostsToFacebook]);
        let destination = create_sync_destination_row(conn, &owner, "123");
        let post = create_post(conn, Some(&owner), PostOpts::default());
        create_post_sync_destination_row(conn, &post, &destination);

        delete_post_sync_destination(
            DeletePostSyncDestinationRequest {
                post_id: post.id.to_proto_id(),
                sync_destination_id: destination.id.to_proto_id(),
            },
            &owner,
            conn,
        )
        .expect("owner delete should succeed");

        use diesel::prelude::*;
        use crate::schema::post_sync_destinations;
        let remaining: i64 = post_sync_destinations::table
            .filter(post_sync_destinations::post_id.eq(post.id))
            .filter(post_sync_destinations::sync_destination_id.eq(destination.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}
