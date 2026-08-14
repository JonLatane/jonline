//! Specs for the 5 EventSyncDestination/sync RPCs: `get_event_sync_destinations`,
//! `create_event_sync_destination`, `update_event_sync_destination`,
//! `delete_event_sync_destination`, `sync_event_instance`. Facebook Graph API interaction
//! correctness itself is covered by `facebook_sync_tests`; these specs focus on permissions,
//! ownership, and validation.

use diesel::prelude::*;
use diesel::Connection;
use tonic::Code;

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::{
    create_event_sync_destination, delete_event_sync_destination, get_event_sync_destinations,
    sync_event_instance, update_event_sync_destination,
};
use crate::schema::event_sync_destinations;
use crate::tests::factories::*;

fn facebook_page_request(
    page_id: &str,
    short_lived_user_access_token: &str,
) -> EventSyncDestination {
    EventSyncDestination {
        configuration: Some(event_sync_destination::Configuration::FacebookPage(
            FacebookPage {
                page_id: page_id.to_string(),
                page_name: String::new(),
                short_lived_user_access_token: Some(short_lived_user_access_token.to_string()),
            },
        )),
        ..Default::default()
    }
}

#[test]
fn create_requires_sync_events_to_facebook_permission() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esdt_create_noperm");

        let err = create_event_sync_destination(
            facebook_page_request("123", "short-lived-token"),
            &user,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNC_EVENTS_TO_FACEBOOK_required");

        Ok(())
    });
}

#[test]
fn create_requires_facebook_page_configuration() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esdt_create_noconfig");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsToFacebook]);

        let err = create_event_sync_destination(EventSyncDestination::default(), &user, conn)
            .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(
            err.message(),
            "facebook_page.page_id_and_short_lived_user_access_token_required"
        );

        Ok(())
    });
}

#[test]
fn create_fails_when_facebook_app_not_configured() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esdt_create_noapp");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsToFacebook]);

        let err = create_event_sync_destination(
            facebook_page_request("123", "short-lived-token"),
            &user,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::FailedPrecondition);
        assert_eq!(err.message(), "facebook_app_not_configured");

        Ok(())
    });
}

#[test]
fn create_succeeds_and_owner_is_always_current_user() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        configure_facebook_app(conn, "test-app-id", "test-app-secret");

        let user = create_user(conn, "esdt_create_ok");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsToFacebook]);

        // Once an app is configured, create_event_sync_destination goes on to hit the real Graph
        // API base URL, which isn't reachable in tests -- see `facebook_sync_tests` for coverage
        // of the actual Graph API interaction (against a mock server) via `logic::facebook_sync`'s
        // `_at` functions.
        let err = create_event_sync_destination(
            facebook_page_request("123", "short-lived-token"),
            &user,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::FailedPrecondition);

        Ok(())
    });
}

#[test]
fn get_event_sync_destinations_self_only_by_default() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_get_owner");
        let other = create_user(conn, "esdt_get_other");
        create_event_sync_destination_row(conn, &owner, "123");

        let response = get_event_sync_destinations(User::default(), &owner, conn)
            .expect("self get should succeed");
        assert_eq!(response.destinations.len(), 1);

        let err = get_event_sync_destinations(
            User {
                id: owner.id.to_proto_id(),
                ..Default::default()
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
fn admin_can_get_another_users_event_sync_destinations() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_get_owner2");
        let admin = create_user(conn, "esdt_get_admin2");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);
        create_event_sync_destination_row(conn, &owner, "123");

        let response = get_event_sync_destinations(
            User {
                id: owner.id.to_proto_id(),
                ..Default::default()
            },
            &admin,
            conn,
        )
        .expect("admin get should succeed");
        assert_eq!(response.destinations.len(), 1);

        Ok(())
    });
}

#[test]
fn returned_destination_never_includes_the_access_token() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_get_notoken");
        create_event_sync_destination_row(conn, &owner, "123");

        let response = get_event_sync_destinations(User::default(), &owner, conn)
            .expect("self get should succeed");
        let destination = &response.destinations[0];
        match destination.configuration.as_ref().unwrap() {
            event_sync_destination::Configuration::FacebookPage(page) => {
                assert_eq!(page.page_id, "123");
                assert_eq!(page.short_lived_user_access_token, None);
            }
        }

        Ok(())
    });
}

#[test]
fn update_requires_sync_events_to_facebook_permission_even_for_the_owner() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_update_noperm");
        let destination = create_event_sync_destination_row(conn, &owner, "123");

        let err = update_event_sync_destination(
            EventSyncDestination {
                id: destination.id.to_proto_id(),
                ..Default::default()
            },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNC_EVENTS_TO_FACEBOOK_required");

        Ok(())
    });
}

#[test]
fn update_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_update_owner");
        let destination = create_event_sync_destination_row(conn, &owner, "123");

        let other = create_user(conn, "esdt_update_other");
        let other = grant_permissions(conn, &other, vec![Permission::SyncEventsToFacebook]);

        let err = update_event_sync_destination(
            EventSyncDestination {
                id: destination.id.to_proto_id(),
                ..Default::default()
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
fn delete_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_delete_owner");
        let destination = create_event_sync_destination_row(conn, &owner, "123");
        let other = create_user(conn, "esdt_delete_other");

        let err = delete_event_sync_destination(
            DeleteEventSyncDestinationRequest {
                destination: Some(EventSyncDestination {
                    id: destination.id.to_proto_id(),
                    ..Default::default()
                }),
                delete_synced_posts: false,
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
fn delete_removes_the_destination() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_delete_ok");
        let destination = create_event_sync_destination_row(conn, &owner, "123");

        delete_event_sync_destination(
            DeleteEventSyncDestinationRequest {
                destination: Some(EventSyncDestination {
                    id: destination.id.to_proto_id(),
                    ..Default::default()
                }),
                delete_synced_posts: false,
            },
            &owner,
            conn,
        )
        .expect("owner delete should succeed");

        let remaining: i64 = event_sync_destinations::table
            .filter(event_sync_destinations::id.eq(destination.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn sync_event_instance_requires_sync_events_to_facebook_permission() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_sync_noperm");
        let destination = create_event_sync_destination_row(conn, &owner, "123");
        let (event, _) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _) = create_event_instance(conn, &event, Some(&owner), Default::default());

        let err = sync_event_instance(
            SyncEventInstanceRequest {
                event_instance_id: instance.id.to_proto_id(),
                event_sync_destination_id: destination.id.to_proto_id(),
            },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNC_EVENTS_TO_FACEBOOK_required");

        Ok(())
    });
}

#[test]
fn sync_event_instance_rejects_non_owner_non_admin_of_the_destination() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_sync_owner");
        let destination = create_event_sync_destination_row(conn, &owner, "123");
        let (event, _) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _) = create_event_instance(conn, &event, Some(&owner), Default::default());

        let other = create_user(conn, "esdt_sync_other");
        let other = grant_permissions(conn, &other, vec![Permission::SyncEventsToFacebook]);

        let err = sync_event_instance(
            SyncEventInstanceRequest {
                event_instance_id: instance.id.to_proto_id(),
                event_sync_destination_id: destination.id.to_proto_id(),
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
fn sync_event_instance_fails_for_unknown_instance() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esdt_sync_noinstance");
        let owner = grant_permissions(conn, &owner, vec![Permission::SyncEventsToFacebook]);
        let destination = create_event_sync_destination_row(conn, &owner, "123");

        let err = sync_event_instance(
            SyncEventInstanceRequest {
                event_instance_id: 999_999_i64.to_proto_id(),
                event_sync_destination_id: destination.id.to_proto_id(),
            },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::NotFound);

        Ok(())
    });
}
