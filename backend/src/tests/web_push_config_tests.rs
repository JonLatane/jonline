//! Specs for `ConfigureServer`'s handling of `WebPushConfig.private_vapid_key`: it's write-only
//! (never sent back to a client) and an empty incoming value is a deliberate no-op rather than a
//! clear -- mirrors `configure_server_tests`' own specs for `FacebookAuthConfig.app_secret`, see
//! that module's doc comment and `configure_server`'s own doc comment on the merge.

use diesel::Connection;

use crate::db_connection::PgPooledConnection;
use crate::protos::*;
use crate::rpcs::{configure_server, get_server_configuration_model, get_server_configuration_proto};
use crate::tests::factories::*;

/// Mirrors `configure_server_tests::facebook_auth_request` -- starts from a fully-populated,
/// freshly-fetched `ServerConfiguration` (real callers always fetch-then-mutate) and overlays
/// just `web_push_config`.
fn web_push_config_request(
    conn: &mut PgPooledConnection,
    public_vapid_key: &str,
    private_vapid_key: &str,
) -> ServerConfiguration {
    let mut config = get_server_configuration_proto(conn).expect("failed to fetch base config");
    config.web_push_config = Some(WebPushConfig {
        public_vapid_key: public_vapid_key.to_string(),
        private_vapid_key: private_vapid_key.to_string(),
    });
    config
}

#[test]
fn private_vapid_key_is_never_returned_to_the_client() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_key_hidden");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let updated = configure_server(
            web_push_config_request(conn, "public-key-1", "super-secret-key"),
            &admin,
            conn,
        )
        .expect("configure should succeed");

        let web_push_config = updated.web_push_config.expect("web_push_config should be set");
        assert_eq!(web_push_config.public_vapid_key, "public-key-1");
        assert_eq!(web_push_config.private_vapid_key, "");

        Ok(())
    });
}

#[test]
fn empty_private_vapid_key_preserves_the_previously_stored_one() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_key_preserved");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        configure_server(
            web_push_config_request(conn, "public-key-1", "super-secret-key"),
            &admin,
            conn,
        )
        .expect("first configure should succeed");

        // Changing just the public key, with private_vapid_key left blank (as the client always
        // sends it, since it never gets the real value back to resend).
        configure_server(
            web_push_config_request(conn, "public-key-2", ""),
            &admin,
            conn,
        )
        .expect("second configure should succeed");

        let stored: WebPushConfig = get_server_configuration_model(conn)
            .expect("failed to fetch stored config")
            .web_push_config
            .and_then(|c| serde_json::from_value(c).ok())
            .expect("web_push_config should still be configured");
        assert_eq!(stored.public_vapid_key, "public-key-2");
        assert_eq!(stored.private_vapid_key, "super-secret-key");

        Ok(())
    });
}

#[test]
fn setting_web_push_config_to_none_clears_the_stored_config() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_key_cleared");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        configure_server(
            web_push_config_request(conn, "public-key-1", "super-secret-key"),
            &admin,
            conn,
        )
        .expect("first configure should succeed");

        let mut clearing_config =
            get_server_configuration_proto(conn).expect("failed to fetch base config");
        clearing_config.web_push_config = None;
        configure_server(clearing_config, &admin, conn).expect("clearing configure should succeed");

        let stored = get_server_configuration_model(conn).expect("failed to fetch stored config");
        assert!(stored.web_push_config.is_none());

        Ok(())
    });
}
