//! Regression test for a production bug in `web_push::stored_web_push_config`'s own doc comment:
//! reading `web_push_config` via `.to_proto()` (the client-facing path) always blanks
//! `private_vapid_key`, so a naive implementation would read back an always-empty key even with a
//! fully valid one stored -- exactly what happened in production. Lives here (rather than inline
//! in `web_push/mod.rs`, alongside its module's other tests) because `main.rs` independently
//! redeclares `pub mod web_push;`, so that file is compiled twice -- once under the `jonline` lib
//! crate root (where `crate::tests` exists) and once under the `jonline` bin crate root (where it
//! doesn't) -- and a `crate::tests::factories` reference inside it fails to resolve for the latter.

use diesel::Connection;

use crate::protos::*;
use crate::rpcs::{configure_server, get_server_configuration_proto};
use crate::tests::factories::*;
use crate::web_push::stored_web_push_config;

/// A real 32-byte VAPID private key, base64url-no-pad encoded -- lifted from the `web-push`
/// crate's own test fixtures (`vapid::builder::tests::PRIVATE_BASE64`), so this is a known-good
/// value rather than something hand-rolled that might not actually decode to a valid P-256 scalar.
const VALID_PRIVATE_KEY: &str = "IQ9Ur0ykXoHS9gzfYX0aBjy9lvdrjx_PFUXmie9YRcY";

#[test]
fn stored_web_push_config_returns_the_unblanked_private_key() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wp_stored_config_unblanked");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let mut config =
            get_server_configuration_proto(conn).expect("failed to fetch base config");
        config.web_push_config = Some(WebPushConfig {
            public_vapid_key: "public-key".to_string(),
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
