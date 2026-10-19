//! Specs for `upsert_rsvp`'s attendee-limit enforcement: `EventInfo.max_attendees`, overridden per
//! `Occasion` by `OccasionRsvpInfo.max_attendees`. Only `GOING` RSVPs with passing moderation count
//! against the limit (by `number_of_guests`), so interested/pending ones never use up capacity.

use diesel::prelude::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::upsert_rsvp;
use crate::schema::occasions;
use crate::tests::factories::*;

fn user_rsvp(
    occasion: &models::Occasion,
    user: &models::User,
    guests: u32,
    status: RsvpStatus,
) -> Rsvp {
    Rsvp {
        occasion_id: occasion.post_id.to_proto_id(),
        attendee: Some(rsvp::Attendee::UserAttendee(UserAttendee {
            user_id: user.id.to_proto_id(),
            ..Default::default()
        })),
        number_of_guests: guests,
        status: status as i32,
        ..Default::default()
    }
}

mod attendee_limit_specs {
    use super::*;

    #[test]
    fn going_rsvps_are_limited_by_the_events_max_attendees_but_interested_ones_are_not() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let owner = create_user(conn, "limit_owner");
            let (event, _) = create_event(
                conn,
                &owner,
                EventOpts {
                    info: json!({"max_attendees": 3}),
                    default_occasion: None,
                    ..Default::default()
                },
            );
            let (occasion, _) = create_occasion(conn, &event, Some(&owner), OccasionOpts::default());
            let alice = create_user(conn, "limit_alice");
            let bob = create_user(conn, "limit_bob");

            upsert_rsvp(user_rsvp(&occasion, &alice, 2, RsvpStatus::Going), &Some(&alice), conn)
                .expect("2 of 3 fits");

            let err = upsert_rsvp(user_rsvp(&occasion, &bob, 2, RsvpStatus::Going), &Some(&bob), conn)
                .expect_err("2 more would make 4 of 3");
            assert_eq!(err.code(), Code::FailedPrecondition);
            assert_eq!(err.message(), "attendee_limit_reached");

            // Nothing was written for the rejected RSVP.
            let bob_rows: i64 = crate::schema::rsvps::table
                .filter(crate::schema::rsvps::user_id.eq(bob.id))
                .count()
                .get_result(conn)
                .unwrap();
            assert_eq!(bob_rows, 0);

            // Interested RSVPs don't count, and a smaller GOING one still fits.
            upsert_rsvp(user_rsvp(&occasion, &bob, 5, RsvpStatus::Interested), &Some(&bob), conn)
                .expect("interested RSVPs aren't limited");
            upsert_rsvp(user_rsvp(&occasion, &bob, 1, RsvpStatus::Going), &Some(&bob), conn)
                .expect("1 more makes exactly 3 of 3");

            // Growing an existing GOING RSVP past the limit is rejected too.
            let err = upsert_rsvp(user_rsvp(&occasion, &bob, 2, RsvpStatus::Going), &Some(&bob), conn)
                .expect_err("bob going from 1 to 2 would make 4 of 3");
            assert_eq!(err.message(), "attendee_limit_reached");

            Ok(())
        });
    }

    #[test]
    fn an_occasions_own_limit_overrides_the_events() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let owner = create_user(conn, "override_owner");
            let (event, _) = create_event(
                conn,
                &owner,
                EventOpts {
                    info: json!({"max_attendees": 1}),
                    default_occasion: None,
                    ..Default::default()
                },
            );
            let (occasion, _) = create_occasion(conn, &event, Some(&owner), OccasionOpts::default());
            diesel::update(occasions::table.filter(occasions::post_id.eq(occasion.post_id)))
                .set(occasions::info.eq(json!({"rsvp_info": {"max_attendees": 4}})))
                .execute(conn)
                .unwrap();
            let alice = create_user(conn, "override_alice");

            upsert_rsvp(user_rsvp(&occasion, &alice, 4, RsvpStatus::Going), &Some(&alice), conn)
                .expect("the occasion's limit of 4 wins over the event's 1");
            Ok(())
        });
    }

    #[test]
    fn approving_a_pending_going_rsvp_is_checked_against_the_limit() {
        let mut conn = test_conn();
        conn.test_transaction::<_, Status, _>(|conn| {
            let owner = create_user(conn, "approve_owner");
            let (event, _) = create_event(
                conn,
                &owner,
                EventOpts {
                    info: json!({"max_attendees": 2}),
                    default_occasion: None,
                    ..Default::default()
                },
            );
            let (occasion, _) = create_occasion(conn, &event, Some(&owner), OccasionOpts::default());
            let alice = create_user(conn, "approve_alice");
            upsert_rsvp(user_rsvp(&occasion, &alice, 2, RsvpStatus::Going), &Some(&alice), conn)
                .expect("fills the event");

            // A pending anonymous RSVP isn't counted, so it can exist while the event is full...
            create_rsvp(
                conn,
                &occasion,
                RsvpOpts {
                    anonymous_attendee: Some(json!({"name": "Guest", "auth_token": "tok"})),
                    status: RsvpStatus::Going,
                    moderation: Moderation::Pending,
                    ..Default::default()
                },
            );

            // ...but the owner can't approve it over the limit.
            let approve = Rsvp {
                occasion_id: occasion.post_id.to_proto_id(),
                attendee: Some(rsvp::Attendee::AnonymousAttendee(AnonymousAttendee {
                    name: "Guest".to_string(),
                    auth_token: Some("tok".to_string()),
                    ..Default::default()
                })),
                number_of_guests: 1,
                status: RsvpStatus::Going as i32,
                moderation: Moderation::Approved as i32,
                ..Default::default()
            };
            let err = upsert_rsvp(approve, &Some(&owner), conn)
                .expect_err("approving would make 3 of 2");
            assert_eq!(err.message(), "attendee_limit_reached");
            Ok(())
        });
    }
}
