//! Specs for the 4 EventSyncSource RPCs: `get_event_sync_sources`, `create_event_sync_source`,
//! `update_event_sync_source`, `delete_event_sync_source`. Sync/parsing correctness itself is
//! covered by `event_sync_tests`; these specs focus on permissions, ownership, and the
//! create-deletes-itself-on-failed-initial-sync/delete_synced_events contracts.

use diesel::prelude::*;
use diesel::Connection;
use tonic::Code;

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::{
    create_event_sync_source, delete_event_sync_source, get_event_sync_sources, update_event_sync_source,
};
use crate::schema::{event_sync_sources, events};
use crate::tests::factories::*;

fn ics_source_request(url: &str) -> EventSyncSource {
    EventSyncSource {
        configuration: Some(event_sync_source::Configuration::IcsSubscriptionUrl(url.to_string())),
        ..Default::default()
    }
}

const EMPTY_ICS: &str = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nEND:VCALENDAR\r\n";

#[test]
fn create_requires_synchronize_events_permission() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esrt_create_noperm");

        let err = create_event_sync_source(ics_source_request("http://example.invalid/cal.ics"), &user, conn)
            .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNCHRONIZE_EVENTS_required");

        Ok(())
    });
}

#[test]
fn create_requires_ics_subscription_url() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esrt_create_nourl");
        let user = grant_permissions(conn, &user, vec![Permission::SynchronizeEvents]);

        let err = create_event_sync_source(EventSyncSource::default(), &user, conn).unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "ics_subscription_url_required");

        Ok(())
    });
}

#[test]
fn create_succeeds_and_owner_is_always_current_user() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esrt_create_ok");
        let user = grant_permissions(conn, &user, vec![Permission::SynchronizeEvents]);
        let url = serve_ics(EMPTY_ICS);

        let mut request = ics_source_request(&url);
        // Even if a caller sets an `owner`, creation is always for the current user.
        request.owner = Some(models::Author {
            id: 999_999,
            username: "someone-else".to_string(),
            avatar_media_id: None,
            real_name: "Someone Else".to_string(),
            permissions: serde_json::json!([]),
        }.to_proto(None));

        let created = create_event_sync_source(request, &user, conn).expect("create should succeed");
        assert_eq!(created.owner.unwrap().user_id, user.id.to_proto_id());
        assert!(created.last_synced_at.is_some(), "a successful create should sync immediately");

        Ok(())
    });
}

#[test]
fn create_deletes_the_source_if_initial_sync_fails() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "esrt_create_failsync");
        let user = grant_permissions(conn, &user, vec![Permission::SynchronizeEvents]);

        // Port 1 is a privileged port nothing is listening on -- fails fast without needing
        // real network access.
        let err = create_event_sync_source(ics_source_request("http://127.0.0.1:1/cal.ics"), &user, conn)
            .unwrap_err();
        assert_eq!(err.code(), Code::FailedPrecondition);
        assert_eq!(err.message(), "ics_fetch_failed");

        let remaining: i64 = event_sync_sources::table
            .filter(event_sync_sources::user_id.eq(user.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0, "a source whose initial sync fails should be deleted, not left behind");

        Ok(())
    });
}

#[test]
fn admin_can_create_without_synchronize_events_permission_but_owner_is_still_self() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "esrt_create_admin");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);
        let url = serve_ics(EMPTY_ICS);

        let created = create_event_sync_source(ics_source_request(&url), &admin, conn).expect("admin create should succeed");
        assert_eq!(created.owner.unwrap().user_id, admin.id.to_proto_id());

        Ok(())
    });
}

#[test]
fn get_event_sync_sources_self_only_by_default() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_get_owner");
        let other = create_user(conn, "esrt_get_other");
        create_event_sync_source_row(conn, &owner, "http://example.invalid/cal.ics");

        let response = get_event_sync_sources(User::default(), &owner, conn).expect("self get should succeed");
        assert_eq!(response.sources.len(), 1);

        let err = get_event_sync_sources(
            User { id: owner.id.to_proto_id(), ..Default::default() },
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
fn admin_can_get_another_users_event_sync_sources() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_get_owner2");
        let admin = create_user(conn, "esrt_get_admin2");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);
        create_event_sync_source_row(conn, &owner, "http://example.invalid/cal.ics");

        let response = get_event_sync_sources(
            User { id: owner.id.to_proto_id(), ..Default::default() },
            &admin,
            conn,
        )
        .expect("admin get should succeed");
        assert_eq!(response.sources.len(), 1);

        Ok(())
    });
}

#[test]
fn update_requires_synchronize_events_permission_even_for_the_owner() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_update_noperm");
        let source = create_event_sync_source_row(conn, &owner, "http://example.invalid/cal.ics");

        let err = update_event_sync_source(
            EventSyncSource { id: source.id.to_proto_id(), ..Default::default() },
            &owner,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNCHRONIZE_EVENTS_required");

        Ok(())
    });
}

#[test]
fn update_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_update_owner");
        let source = create_event_sync_source_row(conn, &owner, "http://example.invalid/cal.ics");

        let other = create_user(conn, "esrt_update_other");
        let other = grant_permissions(conn, &other, vec![Permission::SynchronizeEvents]);

        let err = update_event_sync_source(
            EventSyncSource { id: source.id.to_proto_id(), ..Default::default() },
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
fn owner_can_refresh_and_change_interval() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_update_ok");
        let owner = grant_permissions(conn, &owner, vec![Permission::SynchronizeEvents]);
        let url = serve_ics(EMPTY_ICS);
        let source = create_event_sync_source_row(conn, &owner, &url);

        let updated = update_event_sync_source(
            EventSyncSource {
                id: source.id.to_proto_id(),
                sync_interval_seconds: 900,
                ..Default::default()
            },
            &owner,
            conn,
        )
        .expect("owner update should succeed");
        assert_eq!(updated.sync_interval_seconds, 900);
        assert!(updated.last_synced_at.is_some());

        Ok(())
    });
}

#[test]
fn admin_can_update_another_users_source() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_update_owner3");
        let url = serve_ics(EMPTY_ICS);
        let source = create_event_sync_source_row(conn, &owner, &url);

        let admin = create_user(conn, "esrt_update_admin3");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let updated = update_event_sync_source(
            EventSyncSource {
                id: source.id.to_proto_id(),
                sync_interval_seconds: 300,
                ..Default::default()
            },
            &admin,
            conn,
        )
        .expect("admin update should succeed");
        assert_eq!(updated.sync_interval_seconds, 300);
        assert_eq!(updated.owner.unwrap().user_id, owner.id.to_proto_id());

        Ok(())
    });
}

#[test]
fn delete_rejects_non_owner_non_admin() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_delete_owner");
        let source = create_event_sync_source_row(conn, &owner, "http://example.invalid/cal.ics");
        let other = create_user(conn, "esrt_delete_other");

        let err = delete_event_sync_source(
            DeleteEventSyncSourceRequest {
                source: Some(EventSyncSource { id: source.id.to_proto_id(), ..Default::default() }),
                delete_synced_events: false,
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
fn delete_without_delete_synced_events_detaches_but_keeps_events() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_delete_detach");
        let url = serve_ics(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:detach-1\r\nDTSTART:20990101T090000Z\r\nDTEND:20990101T100000Z\r\nSUMMARY:Detach Me\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
        );
        let owner = grant_permissions(conn, &owner, vec![Permission::SynchronizeEvents]);
        let created = create_event_sync_source(ics_source_request(&url), &owner, conn).expect("create should succeed");

        let event_id_before: i64 = events::table
            .filter(events::event_sync_source_id.eq(created.id.to_db_id().unwrap()))
            .select(events::id)
            .first(conn)
            .unwrap();

        delete_event_sync_source(
            DeleteEventSyncSourceRequest {
                source: Some(created.clone()),
                delete_synced_events: false,
            },
            &owner,
            conn,
        )
        .expect("delete should succeed");

        let event_after: models::Event = events::table
            .filter(events::id.eq(event_id_before))
            .first(conn)
            .expect("event should still exist after a non-destructive delete");
        assert_eq!(event_after.event_sync_source_id, None, "event should be detached from the deleted source");

        let remaining_sources: i64 = event_sync_sources::table
            .filter(event_sync_sources::id.eq(created.id.to_db_id().unwrap()))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining_sources, 0);

        Ok(())
    });
}

#[test]
fn delete_with_delete_synced_events_removes_events_too() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "esrt_delete_cascade");
        let url = serve_ics(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:cascade-1\r\nDTSTART:20990101T090000Z\r\nDTEND:20990101T100000Z\r\nSUMMARY:Delete Me Too\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
        );
        let owner = grant_permissions(conn, &owner, vec![Permission::SynchronizeEvents]);
        let created = create_event_sync_source(ics_source_request(&url), &owner, conn).expect("create should succeed");

        let event_id_before: i64 = events::table
            .filter(events::event_sync_source_id.eq(created.id.to_db_id().unwrap()))
            .select(events::id)
            .first(conn)
            .unwrap();

        delete_event_sync_source(
            DeleteEventSyncSourceRequest {
                source: Some(created.clone()),
                delete_synced_events: true,
            },
            &owner,
            conn,
        )
        .expect("delete should succeed");

        let remaining_event: Option<models::Event> = events::table
            .filter(events::id.eq(event_id_before))
            .first(conn)
            .optional()
            .unwrap();
        assert!(remaining_event.is_none(), "delete_synced_events should remove the synced event");

        Ok(())
    });
}
