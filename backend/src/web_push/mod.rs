use std::sync::Arc;

use serde::Serialize;
use web_push::{
    ContentEncoding, IsahcWebPushClient, SubscriptionInfo, VapidSignatureBuilder, WebPushClient,
    WebPushError, WebPushMessageBuilder,
};

use crate::db_connection::PgPool;
use crate::marshaling::ToProtoServerConfiguration;
use crate::models;
use crate::rpcs::get_server_configuration_model;

/// The JSON shape delivered (encrypted, per the Web Push standard) to the browser's service
/// worker `push` event -- see this file's own module doc comment. Kept deliberately small: no
/// message id/deep link yet, since there's no frontend service worker consuming this yet either.
#[derive(Serialize)]
struct PushPayload<'a> {
    title: &'a str,
    body: &'a str,
}

/// Fans a new-Message notification out to every push subscription belonging to
/// `recipient_user_ids`, via the server's configured `WebPushConfig` (VAPID keys) -- see
/// `send_message::send_message`/`web::email::create_email_message`, this module's two callers.
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
) {
    let Ok(handle) = tokio::runtime::Handle::try_current() else {
        log::warn!("notify_message_recipients: no Tokio runtime available, skipping");
        return;
    };
    handle.spawn(async move {
        if let Err(error) =
            send_message_notifications(pool, recipient_user_ids, &title, &body).await
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
) -> Result<(), String> {
    let mut conn = pool.get().map_err(|e| e.to_string())?;

    let web_push_config = get_server_configuration_model(&mut conn)
        .map_err(|e| e.to_string())?
        .to_proto()
        .web_push_config;
    // No VAPID keys configured on this server -- nothing to sign/send with, and nothing to
    // configure this behind (see `RegisterPushSubscription`'s own doc comment on why registration
    // itself doesn't gate on this).
    let Some(web_push_config) = web_push_config else {
        return Ok(());
    };

    let subscriptions =
        models::get_push_subscriptions_for_users(&recipient_user_ids, &mut conn)
            .map_err(|e| e.to_string())?;
    if subscriptions.is_empty() {
        return Ok(());
    }

    let partial_signature_builder =
        VapidSignatureBuilder::from_base64_no_sub(&web_push_config.private_vapid_key)
            .map_err(|e| format!("{:?}", e))?;
    let client = IsahcWebPushClient::new().map_err(|e| format!("{:?}", e))?;
    let payload = serde_json::to_vec(&PushPayload { title, body }).map_err(|e| e.to_string())?;

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
            // The push service itself says this endpoint is dead -- prune it so it isn't retried
            // on every future Message. Any other error (network blip, server error, bad VAPID
            // config, ...) is just logged; the subscription might still be good next time.
            Err(WebPushError::EndpointNotValid(_)) | Err(WebPushError::EndpointNotFound(_)) => {
                if let Err(e) = models::delete_push_subscription_by_id(subscription.id, &mut conn)
                {
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
