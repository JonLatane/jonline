//! Specs for `web_push`'s own DB-backed helpers (`stored_web_push_config`, `stored_frontend_host`)
//! that need a real `test_conn`/`configure_server` round trip. Lives here (rather than inline in
//! `web_push/mod.rs`, alongside its module's other, DB-free tests) because `main.rs` independently
//! redeclares `pub mod web_push;`, so that file is compiled twice -- once under the `jonline` lib
//! crate root (where `crate::tests` exists) and once under the `jonline` bin crate root (where it
//! doesn't) -- and a `crate::tests::factories` reference inside it fails to resolve for the latter.
//!
//! `stored_web_push_config_returns_the_unblanked_private_key` is a regression test for a real
//! production bug (see that function's own doc comment): reading `web_push_config` via
//! `.to_proto()` (the client-facing path) always blanks `private_vapid_key`, so a naive
//! implementation would read back an always-empty key even with a fully valid one stored.

use diesel::Connection;

use crate::protos::*;
use crate::rpcs::{configure_server, get_server_configuration_proto};
use crate::tests::factories::*;
use crate::web_push::{stored_frontend_host, stored_web_push_config};

/// A real 32-byte VAPID private key, base64url-no-pad encoded -- lifted from the `web-push`
/// crate's own test fixtures (`vapid::builder::tests::PRIVATE_BASE64`), so this is a known-good
/// value rather than something hand-rolled that might not actually decode to a valid P-256 scalar.
const VALID_PRIVATE_KEY: &str = "IQ9Ur0ykXoHS9gzfYX0aBjy9lvdrjx_PFUXmie9YRcY";

/// A real 65-byte VAPID public key (uncompressed P-256 point), base64url-no-pad encoded --
/// `configure_server` now validates this shape (`validate_vapid_public_key`), so a placeholder
/// like `"public-key"` no longer saves successfully.
const VALID_PUBLIC_KEY: &str =
    "BCzG8GfIlqc_jCOKNGc2CvLyWowp3AONLdtlEE3vTlB45AFnm2CpLD6KESfO43K5O_A29tQQLv8w8kmYRTTlyfA";

#[test]
fn stored_web_push_config_returns_the_unblanked_private_key() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wp_stored_config_unblanked");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let mut config =
            get_server_configuration_proto(conn).expect("failed to fetch base config");
        config.web_push_config = Some(WebPushConfig {
            public_vapid_key: VALID_PUBLIC_KEY.to_string(),
            private_vapid_key: VALID_PRIVATE_KEY.to_string(),
        });
        configure_server(config, &admin, conn).expect("configure should succeed");

        let stored = stored_web_push_config(conn)
            .expect("should not error")
            .expect("web_push_config should be set");
        assert_eq!(stored.private_vapid_key, VALID_PRIVATE_KEY);

        Ok(())
    });
}

#[test]
fn stored_frontend_host_returns_the_configured_host() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wp_frontend_host");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let mut config =
            get_server_configuration_proto(conn).expect("failed to fetch base config");
        config.external_cdn_config = Some(ExternalCdnConfig {
            frontend_host: "example.social".to_string(),
            backend_host: "example.social".to_string(),
            ..Default::default()
        });
        configure_server(config, &admin, conn).expect("configure should succeed");

        let host = stored_frontend_host(conn).expect("should not error");
        assert_eq!(host.as_deref(), Some("example.social"));

        Ok(())
    });
}

#[test]
fn stored_frontend_host_is_none_without_a_configured_external_cdn_config() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        // No `configure_server` call at all -- the default config has no `external_cdn_config`.
        let host = stored_frontend_host(conn).expect("should not error");
        assert_eq!(host, None);

        Ok(())
    });
}
