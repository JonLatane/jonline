//! Specs for `GetPushSubscriptionStatus` -- see that RPC's own doc comment on why the frontend
//! needs it at all: a browser only ever exposes its own subscription's `endpoint`, never *who* on
//! the server side is registered against it, which matters once multiple local accounts on the
//! same server can share one browser subscription (see `register_push_subscription`'s own doc
//! comment on why re-registering the same endpoint for another user is fine).

use diesel::Connection;

use crate::protos::*;
use crate::rpcs::{get_push_subscription_status, register_push_subscription, unregister_push_subscription};
use crate::tests::factories::*;

const ENDPOINT: &str = "https://fcm.googleapis.com/fcm/send/some-endpoint-id";

fn subscription_request() -> RegisterPushSubscriptionRequest {
    RegisterPushSubscriptionRequest {
        endpoint: ENDPOINT.to_string(),
        p256dh_key: "some-p256dh-key".to_string(),
        auth_key: "some-auth-key".to_string(),
    }
}

#[test]
fn returns_false_when_never_registered() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "pushstatus_never");

        let status = get_push_subscription_status(
            GetPushSubscriptionStatusRequest { endpoint: ENDPOINT.to_string() },
            &user,
            conn,
        )?;
        assert!(!status.registered);

        Ok(())
    });
}

#[test]
fn returns_true_once_registered() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "pushstatus_registered");
        register_push_subscription(subscription_request(), &user, conn)?;

        let status = get_push_subscription_status(
            GetPushSubscriptionStatusRequest { endpoint: ENDPOINT.to_string() },
            &user,
            conn,
        )?;
        assert!(status.registered);

        Ok(())
    });
}

#[test]
fn returns_false_again_after_unregistering() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "pushstatus_unregistered");
        register_push_subscription(subscription_request(), &user, conn)?;
        unregister_push_subscription(
            UnregisterPushSubscriptionRequest { endpoint: ENDPOINT.to_string() },
            &user,
            conn,
        )?;

        let status = get_push_subscription_status(
            GetPushSubscriptionStatusRequest { endpoint: ENDPOINT.to_string() },
            &user,
            conn,
        )?;
        assert!(!status.registered);

        Ok(())
    });
}

/// The whole point of this RPC (see its own doc comment): two different local accounts can share
/// the exact same browser subscription `endpoint`, but each user's *own* registration is
/// independent -- registering it for one user must not report it as registered for another.
#[test]
fn is_independent_per_user_for_the_same_shared_endpoint() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user_a = create_user(conn, "pushstatus_shared_a");
        let user_b = create_user(conn, "pushstatus_shared_b");
        register_push_subscription(subscription_request(), &user_a, conn)?;

        let status_a = get_push_subscription_status(
            GetPushSubscriptionStatusRequest { endpoint: ENDPOINT.to_string() },
            &user_a,
            conn,
        )?;
        let status_b = get_push_subscription_status(
            GetPushSubscriptionStatusRequest { endpoint: ENDPOINT.to_string() },
            &user_b,
            conn,
        )?;
        assert!(status_a.registered);
        assert!(!status_b.registered);

        Ok(())
    });
}
