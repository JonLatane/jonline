use std::sync::Arc;

use base64::{Engine, prelude::BASE64_URL_SAFE_NO_PAD};
use serde::Serialize;
use web_push::{
    ContentEncoding, IsahcWebPushClient, SubscriptionInfo, VapidSignatureBuilder, WebPushClient,
    WebPushError, WebPushMessageBuilder,
};

use crate::db_connection::PgPool;
use crate::marshaling::ToProtoId;
use crate::models;
use crate::protos;
use crate::rpcs::get_server_configuration_model;

/// The JSON shape delivered (encrypted, per the Web Push standard) to the browser's service
/// worker `push` event -- see this file's own module doc comment. `url` (see
/// `notification_url`) is the full deep link `service-worker.js`'s `notificationclick` handler
/// navigates to -- `None` (omitted entirely, not sent as `null`, via `skip_serializing_if`) when
/// this server has no configured `ExternalCdnConfig.frontend_host` to build one from, in which
/// case that handler just falls back to opening `/`.
#[derive(Serialize)]
struct PushPayload<'a> {
    title: &'a str,
    body: &'a str,
    #[serde(skip_serializing_if = "Option::is_none")]
    url: Option<String>,
}

/// Fans a new-Message notification out to every push subscription belonging to
/// `recipient_user_ids`, via the server's configured `WebPushConfig` (VAPID keys) -- see
/// `send_message::send_message`/`web::email::create_email_message`, this module's two callers.
/// `messaging_group_id`/`message_id` (the raw DB ids, not yet `to_proto_id()`-encoded -- this
/// does that itself, see `notification_url`) are the `Message`'s own, used to build a deep link
/// straight to it (`?messaging_group=<id>#message-<id>`, the same shape
/// `Components.Pages.MessagesPage.groupQueryParams`/`messageDomId` build client-side) rather than
/// just bringing the app to the front with no context.
///
/// Runs entirely in a spawned background task: neither trigger point should have its own
/// response (an in-app `SendMessage` RPC, or Stalwart's inbound-email MTA hook) wait on however
/// long it takes to reach every recipient's push subscriptions, and a failure to notify shouldn't
/// fail the Message send/delivery itself. `pool` is used only inside that task, for its own fresh
/// connection -- the caller's own `conn` can't cross the `tokio::spawn` boundary.
///
/// No-ops (logging a warning, not panicking) if called outside a Tokio runtime -- true of the
/// plain synchronous `#[test]`s in `tests::send_message_tests`, which call `rpcs::send_message`
/// directly rather than through the server's own tonic/Rocket runtimes.
pub fn notify_message_recipients(
    pool: Arc<PgPool>,
    recipient_user_ids: Vec<i64>,
    title: String,
    body: String,
    messaging_group_id: i64,
    message_id: i64,
) {
    let Ok(handle) = tokio::runtime::Handle::try_current() else {
        log::warn!("notify_message_recipients: no Tokio runtime available, skipping");
        return;
    };
    handle.spawn(async move {
        if let Err(error) = send_message_notifications(
            pool,
            recipient_user_ids,
            &title,
            &body,
            messaging_group_id,
            message_id,
        )
        .await
        {
            log::warn!("notify_message_recipients failed: {:?}", error);
        }
    });
}

async fn send_message_notifications(
    pool: Arc<PgPool>,
    recipient_user_ids: Vec<i64>,
    title: &str,
    body: &str,
    messaging_group_id: i64,
    message_id: i64,
) -> Result<(), String> {
    let mut conn = pool.get().map_err(|e| e.to_string())?;

    let web_push_config = stored_web_push_config(&mut conn)?;
    // No VAPID keys configured on this server -- nothing to sign/send with, and nothing to
    // configure this behind (see `RegisterPushSubscription`'s own doc comment on why registration
    // itself doesn't gate on this).
    let Some(web_push_config) = web_push_config else {
        return Ok(());
    };

    let subscriptions = models::get_push_subscriptions_for_users(&recipient_user_ids, &mut conn)
        .map_err(|e| e.to_string())?;
    if subscriptions.is_empty() {
        return Ok(());
    }

    validate_private_vapid_key(&web_push_config.private_vapid_key)?;

    let url = notification_url(&mut conn, messaging_group_id, message_id)?;

    let partial_signature_builder =
        VapidSignatureBuilder::from_base64_no_sub(&web_push_config.private_vapid_key)
            .map_err(|e| format!("{:?}", e))?;
    let client = IsahcWebPushClient::new().map_err(|e| format!("{:?}", e))?;
    let payload =
        serde_json::to_vec(&PushPayload { title, body, url }).map_err(|e| e.to_string())?;

    for subscription in subscriptions {
        let subscription_info = SubscriptionInfo::new(
            subscription.endpoint.clone(),
            subscription.p256dh_key.clone(),
            subscription.auth_key.clone(),
        );

        let send_result = (|| -> Result<_, WebPushError> {
            let signature = partial_signature_builder
                .clone()
                .add_sub_info(&subscription_info)
                .build()?;
            let mut builder = WebPushMessageBuilder::new(&subscription_info);
            builder.set_payload(ContentEncoding::Aes128Gcm, &payload);
            builder.set_vapid_signature(signature);
            builder.build()
        })();

        let send_result = match send_result {
            Ok(message) => client.send(message).await,
            Err(error) => Err(error),
        };

        match send_result {
            Ok(()) => {}
            // The push service itself says this endpoint is dead, or is otherwise permanently
            // unusable -- prune it so it isn't retried on every future Message. Confirmed in
            // production: a subscription registered under a since-rotated VAPID public key (see
            // today's key-corruption/regeneration saga) comes back as `BadRequest` with FCM's own
            // `{"reason":"VapidPkHashMismatch"}` -- that subscription's `endpoint` is permanently
            // tied to the *old* key and will never succeed no matter how many times it's retried,
            // same as an outright-dead endpoint. Any other error (network blip, server error, a
            // currently-misconfigured VAPID key that might get fixed) is just logged; those
            // aren't necessarily about this one subscription, so the subscription might still be
            // good next time.
            Err(WebPushError::EndpointNotValid(_))
            | Err(WebPushError::EndpointNotFound(_))
            | Err(WebPushError::BadRequest(_)) => {
                if let Err(e) = models::delete_push_subscription_by_id(subscription.id, &mut conn) {
                    log::warn!(
                        "Failed to prune dead push subscription {}: {:?}",
                        subscription.id,
                        e
                    );
                }
            }
            Err(error) => {
                log::warn!(
                    "Failed to send push notification to subscription {}: {:?}",
                    subscription.id,
                    error
                );
            }
        }
    }

    Ok(())
}

/// Fetches this server's configured `WebPushConfig`, if any, with `private_vapid_key` intact.
///
/// Deliberately *not* `get_server_configuration_model(conn)?.to_proto().web_push_config` --
/// `to_proto` (see `ToProtoServerConfiguration`) always blanks `private_vapid_key` before a
/// *client* sees it, since it's meant to never leave the server. Going through that here would
/// blank it before this, the one place actually meant to use it, ever sees it either -- confirmed
/// in production: every send silently no-op'd (`validate_private_vapid_key` rightfully rejecting
/// the now-always-empty key) even with a fully valid key stored. Parsing the raw model's own
/// `web_push_config` column directly is the same "read the unblanked value" pattern
/// `configure_server`'s own merge-on-blank block already relies on.
pub(crate) fn stored_web_push_config(
    conn: &mut crate::db_connection::PgPooledConnection,
) -> Result<Option<protos::WebPushConfig>, String> {
    Ok(get_server_configuration_model(conn)
        .map_err(|e| e.to_string())?
        .web_push_config
        .and_then(|c| serde_json::from_value::<protos::WebPushConfig>(c).ok()))
}

/// Builds the full `https://<frontend_host>/messages?messaging_group=<id>#message-<id>` deep
/// link a push notification's `PushPayload.url` should point to -- the same query
/// param/fragment shape `Components.Pages.MessagesPage.groupQueryParams`/`messageDomId` build
/// client-side for a `MessagingGroup` conversation, given plain ids (no `@<host>` federation
/// suffix): a notification is always about a Message that lives on *this* server, so the
/// deep link's own host and the Message's group's host are always the same one, exactly the case
/// `groupRouteId` already renders as a bare id with no suffix.
///
/// `Message.messaging_group_id` is never null (`find_or_create_messaging_group` runs for every
/// Message, in-app or inbound email alike -- see `send_message`/`web::email::create_email_message`,
/// this function's two callers by way of `send_message_notifications`), so the only reason this
/// can come back `Ok(None)` is `ExternalCdnConfig.frontend_host` itself not being configured --
/// in which case there's no known public host to build a real URL against at all, and
/// `send_message_notifications` just omits `url` from the payload entirely rather than guessing.
pub(crate) fn notification_url(
    conn: &mut crate::db_connection::PgPooledConnection,
    messaging_group_id: i64,
    message_id: i64,
) -> Result<Option<String>, String> {
    let frontend_host = get_server_configuration_model(conn)
        .map_err(|e| e.to_string())?
        .external_cdn_config
        .and_then(|c| serde_json::from_value::<protos::ExternalCdnConfig>(c).ok())
        .map(|c| c.frontend_host);
    Ok(frontend_host.map(|host| {
        format!(
            "https://{}/messages?messaging_group={}#message-{}",
            host,
            messaging_group_id.to_proto_id(),
            message_id.to_proto_id()
        )
    }))
}

/// `VapidSignatureBuilder::from_base64_no_sub` hands its decoded bytes straight to `jwt_simple`'s
/// `ES256KeyPair::from_bytes`, which -- for anything other than exactly 32 bytes (a P-256 private
/// scalar) -- panics via a bare `assert_eq!` instead of returning a `Result`. Confirmed in
/// production: a server with `public_vapid_key` set but `private_vapid_key` still blank (see
/// `configure_server`'s merge-on-blank -- an admin who only ever saved the Public VAPID Key row
/// never actually set this one) crashed both backend pods the moment a message first tried to
/// notify. Decoding and length-checking it ourselves first turns that into an ordinary `Err`
/// `send_message_notifications` already handles gracefully, before ever reaching the panicking
/// call.
fn validate_private_vapid_key(private_vapid_key: &str) -> Result<(), String> {
    let len = BASE64_URL_SAFE_NO_PAD
        .decode(private_vapid_key)
        .map_err(|e| format!("invalid private_vapid_key (not valid base64url): {}", e))?
        .len();
    if len != 32 {
        return Err(format!(
            "invalid private_vapid_key: expected 32 bytes, got {} -- is WebPushConfig only half-configured?",
            len
        ));
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A real 32-byte VAPID private key, base64url-no-pad encoded -- lifted from the `web-push`
    /// crate's own test fixtures (`vapid::builder::tests::PRIVATE_BASE64`), so this is a
    /// known-good value rather than something hand-rolled that might not actually decode to a
    /// valid P-256 scalar.
    const VALID_PRIVATE_KEY: &str = "IQ9Ur0ykXoHS9gzfYX0aBjy9lvdrjx_PFUXmie9YRcY";

    #[test]
    fn empty_private_vapid_key_is_rejected_not_panicked() {
        // The exact production shape: `WebPushConfig.private_vapid_key` still `""` because only
        // the Public VAPID Key row was ever saved (see `configure_server`'s merge-on-blank).
        assert!(validate_private_vapid_key("").is_err());
    }

    #[test]
    fn wrong_length_private_vapid_key_is_rejected() {
        // Valid base64url, but decodes to fewer than 32 bytes.
        assert!(validate_private_vapid_key("AAAAAAAAAAAAAAAAAAAAAA").is_err());
    }

    #[test]
    fn malformed_base64_private_vapid_key_is_rejected() {
        assert!(validate_private_vapid_key("not valid base64url!!!").is_err());
    }

    #[test]
    fn well_formed_private_vapid_key_is_accepted() {
        assert!(validate_private_vapid_key(VALID_PRIVATE_KEY).is_ok());
    }
}
