use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validations::*;

/// Registers (or re-registers) `user`'s subscription to `request.endpoint` -- see
/// `RegisterPushSubscription`'s own RPC doc comment. Doesn't check whether the server actually has
/// a `WebPushConfig`: a subscription with nothing configured to send it a notification is
/// harmless, and rejecting registration here would just make the client special-case a server
/// state it has no other reason to know about ahead of time.
pub fn register_push_subscription(
    request: RegisterPushSubscriptionRequest,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<PushSubscription, Status> {
    validate_length(&request.endpoint, "endpoint", 1, 2048)?;
    validate_length(&request.p256dh_key, "p256dh_key", 1, 255)?;
    validate_length(&request.auth_key, "auth_key", 1, 255)?;

    let subscription = models::upsert_push_subscription(
        &models::NewPushSubscription {
            user_id: user.id,
            endpoint: request.endpoint,
            p256dh_key: request.p256dh_key,
            auth_key: request.auth_key,
        },
        conn,
    )?;

    Ok(subscription.to_proto())
}
