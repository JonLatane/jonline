// use base64::URL_SAFE;
use std::fs::File;
use web_push::*;

pub async fn initialize_push_service() -> Result<(), WebPushError> {
    // This function is a placeholder for the actual implementation
    // of the push service initialization.
    // The actual implementation will be added in the next steps.
    // unimplemented!();

    let endpoint = "https://updates.push.services.mozilla.com/wpush/v1/...";
    let p256dh = "key_from_browser_as_base64";
    let auth = "auth_from_browser_as_base64";

    //You would likely get this by deserializing a browser `pushSubscription` object.
    let subscription_info = SubscriptionInfo::new(endpoint, p256dh, auth);

    //Read signing material for payload.
    let file = File::open("private.pem").unwrap();
    // let builder = VapidSignatureBuilder::from_base64_no_sub(
    //     "IQ9Ur0ykXoHS9gzfYX0aBjy9lvdrjx_PFUXmie9YRcY",
    //     base64::Engine,
    // )
    // .unwrap();
    let mut sig_builder = VapidSignatureBuilder::from_pem(file, &subscription_info)?.build()?;

    //Now add payload and encrypt.
    let mut builder = WebPushMessageBuilder::new(&subscription_info);
    let content = "Encrypted payload to be sent in the notification".as_bytes();
    builder.set_payload(ContentEncoding::Aes128Gcm, content);
    builder.set_vapid_signature(sig_builder);

    let client = IsahcWebPushClient::new()?;

    //Finally, send the notification!
    client.send(builder.build()?).await?;

    Ok(())
}
