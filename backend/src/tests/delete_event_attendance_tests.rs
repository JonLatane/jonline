//! Specs for `delete_event_attendance`: the event owner or the attendee themselves may delete a
//! user-backed attendance; anonymous attendances are gated by a matching `auth_token` instead
//! (see `logic`/`models::get_event_attendance`'s auth_token lookup) rather than by `user`.

use diesel::prelude::*;
use tonic::Code;

use crate::marshaling::*;
use crate::protos::*;
use crate::rpcs::delete_event_attendance;
use crate::schema::event_attendances;
use crate::tests::factories::*;

#[test]
fn event_owner_can_delete_any_attendance() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "deat_owner");
        let (event, _post) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _instance_post) =
            create_event_instance(conn, &event, Some(&owner), EventInstanceOpts::default());
        let attendee = create_user(conn, "deat_attendee");
        create_event_attendance(
            conn,
            &instance,
            EventAttendanceOpts {
                user_id: Some(attendee.id),
                ..Default::default()
            },
        );

        delete_event_attendance(
            EventAttendance {
                event_instance_id: instance.id.to_proto_id(),
                attendee: Some(event_attendance::Attendee::UserAttendee(UserAttendee {
                    user_id: attendee.id.to_proto_id(),
                    ..Default::default()
                })),
                ..Default::default()
            },
            &Some(&owner),
            conn,
        )
        .expect("event owner delete should succeed");

        let remaining: i64 = event_attendances::table
            .filter(event_attendances::event_instance_id.eq(instance.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn attendee_can_delete_their_own_attendance() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "deat_owner2");
        let (event, _post) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _instance_post) =
            create_event_instance(conn, &event, Some(&owner), EventInstanceOpts::default());
        let attendee = create_user(conn, "deat_attendee2");
        create_event_attendance(
            conn,
            &instance,
            EventAttendanceOpts {
                user_id: Some(attendee.id),
                ..Default::default()
            },
        );

        delete_event_attendance(
            EventAttendance {
                event_instance_id: instance.id.to_proto_id(),
                attendee: Some(event_attendance::Attendee::UserAttendee(UserAttendee {
                    user_id: attendee.id.to_proto_id(),
                    ..Default::default()
                })),
                ..Default::default()
            },
            &Some(&attendee),
            conn,
        )
        .expect("attendee self delete should succeed");

        let remaining: i64 = event_attendances::table
            .filter(event_attendances::event_instance_id.eq(instance.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn delete_rejects_an_unrelated_user() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "deat_owner3");
        let (event, _post) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _instance_post) =
            create_event_instance(conn, &event, Some(&owner), EventInstanceOpts::default());
        let attendee = create_user(conn, "deat_attendee3");
        create_event_attendance(
            conn,
            &instance,
            EventAttendanceOpts {
                user_id: Some(attendee.id),
                ..Default::default()
            },
        );
        let bystander = create_user(conn, "deat_bystander");

        let err = delete_event_attendance(
            EventAttendance {
                event_instance_id: instance.id.to_proto_id(),
                attendee: Some(event_attendance::Attendee::UserAttendee(UserAttendee {
                    user_id: attendee.id.to_proto_id(),
                    ..Default::default()
                })),
                ..Default::default()
            },
            &Some(&bystander),
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::PermissionDenied);
        assert_eq!(err.message(), "not_your_event_or_attendance");

        let remaining: i64 = event_attendances::table
            .filter(event_attendances::event_instance_id.eq(instance.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 1, "attendance should survive a rejected delete");

        Ok(())
    });
}

#[test]
fn anonymous_attendance_is_deleted_with_a_matching_auth_token() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "deat_owner4");
        let (event, _post) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _instance_post) =
            create_event_instance(conn, &event, Some(&owner), EventInstanceOpts::default());
        create_event_attendance(
            conn,
            &instance,
            EventAttendanceOpts {
                anonymous_attendee: Some(
                    serde_json::json!({"name": "Anon", "auth_token": "correct-token"}),
                ),
                ..Default::default()
            },
        );

        delete_event_attendance(
            EventAttendance {
                event_instance_id: instance.id.to_proto_id(),
                attendee: Some(event_attendance::Attendee::AnonymousAttendee(
                    AnonymousAttendee {
                        name: "Anon".to_string(),
                        contact_methods: vec![],
                        auth_token: Some("correct-token".to_string()),
                    },
                )),
                ..Default::default()
            },
            &None,
            conn,
        )
        .expect("matching auth_token delete should succeed");

        let remaining: i64 = event_attendances::table
            .filter(event_attendances::event_instance_id.eq(instance.id))
            .count()
            .get_result(conn)
            .unwrap();
        assert_eq!(remaining, 0);

        Ok(())
    });
}

#[test]
fn anonymous_attendance_delete_fails_with_the_wrong_auth_token() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let owner = create_user(conn, "deat_owner5");
        let (event, _post) = create_event(
            conn,
            &owner,
            EventOpts {
                default_instance: None,
                ..Default::default()
            },
        );
        let (instance, _instance_post) =
            create_event_instance(conn, &event, Some(&owner), EventInstanceOpts::default());
        create_event_attendance(
            conn,
            &instance,
            EventAttendanceOpts {
                anonymous_attendee: Some(
                    serde_json::json!({"name": "Anon", "auth_token": "correct-token"}),
                ),
                ..Default::default()
            },
        );

        let err = delete_event_attendance(
            EventAttendance {
                event_instance_id: instance.id.to_proto_id(),
                attendee: Some(event_attendance::Attendee::AnonymousAttendee(
                    AnonymousAttendee {
                        name: "Anon".to_string(),
                        contact_methods: vec![],
                        auth_token: Some("wrong-token".to_string()),
                    },
                )),
                ..Default::default()
            },
            &None,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::NotFound);
        assert_eq!(err.message(), "event_attendance_not_found");

        Ok(())
    });
}
