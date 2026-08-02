//! Cross-checks that `get_events`' embedded `EventInstance.attendances`/`current_user_attendance`
//! (see `attach_event_instance_attendances` in `rpcs::events::get_events`) see *exactly* the same
//! data the dedicated `get_event_attendances` RPC does, for the same viewer: the same set of
//! visible attendances, the same per-row `private_note` redaction, and the same
//! resolved-or-hidden `location`. `attach_event_instance_attendances`'s doc comment explains why
//! these rules are duplicated by hand instead of shared code - this suite is what keeps that
//! duplication honest as either RPC changes.

use std::collections::BTreeMap;

use diesel::prelude::*;
use tonic::Status;

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::{get_event_attendances, get_events};
use crate::tests::factories::*;

const ANONYMOUS_AUTH_TOKEN: &str = "gea_parity_secret_token";

struct Scenario {
    owner: crate::models::User,
    pending_user: crate::models::User,
    approved_user: crate::models::User,
    instance: crate::models::EventInstance,
    approved_attendance: crate::models::EventAttendance,
    pending_attendance: crate::models::EventAttendance,
    anonymous_attendance: crate::models::EventAttendance,
}

fn location_json(address: &str) -> serde_json::Value {
    serde_json::to_value(Location {
        id: "".to_string(),
        creator_id: "".to_string(),
        uniformly_formatted_address: address.to_string(),
    })
    .unwrap()
}

/// A `GlobalPublic` event/instance (owned by `owner`) with `hide_location_until_rsvp_approved`
/// set and a location on the instance, plus three attendances covering every visibility bucket
/// `get_event_attendances` distinguishes: an `Approved` logged-in user, a `Pending` logged-in
/// user, and a `Pending` anonymous attendee (unlocked by `ANONYMOUS_AUTH_TOKEN`).
fn build_scenario(conn: &mut crate::db_connection::PgPooledConnection, suffix: &str) -> Scenario {
    let owner = create_user(conn, &format!("geap_owner_{suffix}"));
    let pending_user = create_user(conn, &format!("geap_pending_{suffix}"));
    let approved_user = create_user(conn, &format!("geap_approved_{suffix}"));

    let (event, _event_post) = create_event(
        conn,
        &owner,
        EventOpts {
            visibility: Visibility::GlobalPublic,
            info: serde_json::json!({ "hide_location_until_rsvp_approved": true }),
            ..Default::default()
        },
    );
    let (instance, _instance_post) = create_event_instance(
        conn,
        &event,
        Some(&owner),
        EventInstanceOpts {
            visibility: Visibility::GlobalPublic,
            location: Some(location_json("123 Main St")),
            ..Default::default()
        },
    );

    let approved_attendance = create_event_attendance(
        conn,
        &instance,
        EventAttendanceOpts {
            user_id: Some(approved_user.id),
            status: AttendanceStatus::Going,
            moderation: Moderation::Approved,
            private_note: "approved user's private note".to_string(),
            ..Default::default()
        },
    );
    let pending_attendance = create_event_attendance(
        conn,
        &instance,
        EventAttendanceOpts {
            user_id: Some(pending_user.id),
            status: AttendanceStatus::Interested,
            moderation: Moderation::Pending,
            private_note: "pending user's private note".to_string(),
            ..Default::default()
        },
    );
    let anonymous_attendance = create_event_attendance(
        conn,
        &instance,
        EventAttendanceOpts {
            anonymous_attendee: Some(serde_json::json!({
                "name": "Anonymous Guest",
                "auth_token": ANONYMOUS_AUTH_TOKEN,
            })),
            status: AttendanceStatus::Interested,
            moderation: Moderation::Pending,
            private_note: "anonymous guest's private note".to_string(),
            ..Default::default()
        },
    );

    Scenario {
        owner,
        pending_user,
        approved_user,
        instance,
        approved_attendance,
        pending_attendance,
        anonymous_attendance,
    }
}

fn via_get_events(
    conn: &mut crate::db_connection::PgPooledConnection,
    user: &Option<&crate::models::User>,
    instance_id: i64,
    anonymous_attendee_auth_token: Option<String>,
) -> EventInstance {
    let response = get_events(
        GetEventsRequest {
            event_instance_id: Some(instance_id.to_proto_id()),
            anonymous_attendee_auth_token,
            ..Default::default()
        },
        user,
        conn,
    )
    .expect("get_events failed");
    response
        .events
        .into_iter()
        .next()
        .expect("get_events returned no event")
        .instances
        .into_iter()
        .find(|instance| instance.id == instance_id.to_proto_id())
        .expect("get_events response is missing the instance")
}

fn via_get_event_attendances(
    conn: &mut crate::db_connection::PgPooledConnection,
    user: &Option<&crate::models::User>,
    instance_id: i64,
    anonymous_attendee_auth_token: Option<String>,
) -> EventAttendances {
    get_event_attendances(
        GetEventAttendancesRequest {
            event_instance_id: instance_id.to_proto_id(),
            anonymous_attendee_auth_token,
        },
        user,
        conn,
    )
    .expect("get_event_attendances failed")
}

fn notes_by_id(attendances: &EventAttendances) -> BTreeMap<String, String> {
    attendances
        .attendances
        .iter()
        .map(|a| (a.id.clone(), a.private_note.clone()))
        .collect()
}

/// Fetches the same instance/viewer combination through both RPCs and asserts they agree on
/// exactly which attendances are visible, each row's `private_note` redaction, and whether the
/// location is revealed - both via `EventAttendances.hidden_location` (present on both RPCs'
/// response shape) and via `EventInstance.location` itself (`get_events`-only, since a plain
/// `get_event_attendances` caller may never have fetched the instance at all).
fn assert_parity(
    conn: &mut crate::db_connection::PgPooledConnection,
    user: &Option<&crate::models::User>,
    instance_id: i64,
    anonymous_attendee_auth_token: Option<String>,
) -> (EventInstance, EventAttendances) {
    let events_instance = via_get_events(
        conn,
        user,
        instance_id,
        anonymous_attendee_auth_token.clone(),
    );
    let attendances =
        via_get_event_attendances(conn, user, instance_id, anonymous_attendee_auth_token);
    let events_attendances = events_instance
        .attendances
        .clone()
        .expect("get_events instance is missing its attendances field");

    assert_eq!(
        notes_by_id(&events_attendances),
        notes_by_id(&attendances),
        "get_events and get_event_attendances disagree on which attendances are visible \
         and/or their private_note redaction"
    );
    assert_eq!(
        events_attendances.hidden_location.is_some(),
        attendances.hidden_location.is_some(),
        "get_events and get_event_attendances disagree on whether the location is revealed"
    );
    assert_eq!(
        events_instance.location.is_some(),
        attendances.hidden_location.is_some(),
        "EventInstance.location should be revealed exactly when EventAttendances.hidden_location is"
    );

    (events_instance, attendances)
}

#[test]
fn public_viewer_sees_only_the_approved_attendance_notes_redacted_and_location_hidden() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let scenario = build_scenario(conn, "pub");

        let (events_instance, attendances) = assert_parity(conn, &None, scenario.instance.id, None);

        assert_eq!(
            notes_by_id(&attendances),
            BTreeMap::from([(scenario.approved_attendance.id.to_proto_id(), "".to_string())]),
            "an unauthenticated viewer should see only the approved attendance, with no private_note"
        );
        assert!(events_instance.location.is_none());
        assert!(events_instance.current_user_attendance.is_none());
        Ok(())
    });
}

#[test]
fn own_pending_attendee_sees_their_own_row_but_location_stays_hidden() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let scenario = build_scenario(conn, "pending");

        let (events_instance, attendances) = assert_parity(
            conn,
            &Some(&scenario.pending_user),
            scenario.instance.id,
            None,
        );

        assert_eq!(
            notes_by_id(&attendances),
            BTreeMap::from([
                (
                    scenario.approved_attendance.id.to_proto_id(),
                    "".to_string()
                ),
                (
                    scenario.pending_attendance.id.to_proto_id(),
                    "pending user's private note".to_string()
                ),
            ]),
            "a pending attendee should see their own private_note but not the approved stranger's"
        );
        assert!(
            events_instance.location.is_none(),
            "a merely-Pending (not Approved) attendee shouldn't unlock the hidden location"
        );
        assert_eq!(
            events_instance
                .current_user_attendance
                .expect("current_user_attendance should be set")
                .id,
            scenario.pending_attendance.id.to_proto_id()
        );
        Ok(())
    });
}

#[test]
fn approved_attendee_unlocks_the_hidden_location() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let scenario = build_scenario(conn, "approved");

        let (events_instance, _attendances) = assert_parity(
            conn,
            &Some(&scenario.approved_user),
            scenario.instance.id,
            None,
        );

        assert!(
            events_instance.location.is_some(),
            "an Approved attendee should unlock the hidden location"
        );
        assert_eq!(
            events_instance
                .current_user_attendance
                .expect("current_user_attendance should be set")
                .id,
            scenario.approved_attendance.id.to_proto_id()
        );
        Ok(())
    });
}

#[test]
fn anonymous_attendee_sees_their_own_pending_row_via_auth_token() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let scenario = build_scenario(conn, "anon");

        let (events_instance, attendances) = assert_parity(
            conn,
            &None,
            scenario.instance.id,
            Some(ANONYMOUS_AUTH_TOKEN.to_string()),
        );

        assert_eq!(
            notes_by_id(&attendances),
            BTreeMap::from([
                (
                    scenario.approved_attendance.id.to_proto_id(),
                    "".to_string()
                ),
                (
                    scenario.anonymous_attendance.id.to_proto_id(),
                    "anonymous guest's private note".to_string()
                ),
            ]),
            "the matching auth token should unlock only the anonymous attendee's own row"
        );
        assert!(
            events_instance.location.is_none(),
            "the anonymous attendee is only Pending, so the location should stay hidden"
        );
        assert_eq!(
            events_instance
                .current_user_attendance
                .expect("current_user_attendance should be set")
                .id,
            scenario.anonymous_attendance.id.to_proto_id()
        );
        Ok(())
    });
}

#[test]
fn wrong_auth_token_is_treated_like_no_token() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let scenario = build_scenario(conn, "wrongtoken");

        let (events_instance, attendances) = assert_parity(
            conn,
            &None,
            scenario.instance.id,
            Some("not-the-right-token".to_string()),
        );

        assert_eq!(
            notes_by_id(&attendances),
            BTreeMap::from([(
                scenario.approved_attendance.id.to_proto_id(),
                "".to_string()
            )]),
        );
        assert!(events_instance.location.is_none());
        assert!(events_instance.current_user_attendance.is_none());
        Ok(())
    });
}

#[test]
fn event_owner_sees_every_attendance_unredacted_and_the_real_location() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let scenario = build_scenario(conn, "owner");

        let (events_instance, attendances) =
            assert_parity(conn, &Some(&scenario.owner), scenario.instance.id, None);

        assert_eq!(
            notes_by_id(&attendances),
            BTreeMap::from([
                (
                    scenario.approved_attendance.id.to_proto_id(),
                    "approved user's private note".to_string()
                ),
                (
                    scenario.pending_attendance.id.to_proto_id(),
                    "pending user's private note".to_string()
                ),
                (
                    scenario.anonymous_attendance.id.to_proto_id(),
                    "anonymous guest's private note".to_string()
                ),
            ]),
            "the event owner should see every attendance's private_note, moderation status aside"
        );
        assert!(events_instance.location.is_some());
        assert!(
            events_instance.current_user_attendance.is_none(),
            "the owner never RSVP'd to their own event in this scenario"
        );
        Ok(())
    });
}
