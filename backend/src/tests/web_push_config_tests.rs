//! Specs for `ConfigureServer`'s handling of `WebPushConfig.private_vapid_key`: it's write-only
//! (never sent back to a client) and an empty incoming value is a deliberate no-op rather than a
//! clear -- mirrors `configure_server_tests`' own specs for `FacebookAuthConfig.app_secret`, see
//! that module's doc comment and `configure_server`'s own doc comment on the merge.

use diesel::Connection;

use crate::db_connection::PgPooledConnection;
use crate::protos::*;
use crate::rpcs::{configure_server, get_server_configuration_model, get_server_configuration_proto};
use crate::tests::factories::*;

/// Two distinct, real, well-formed VAPID public keys (65-byte uncompressed P-256 points,
/// base64url-no-pad) -- validated (`validate_vapid_public_key`) since `configure_server` now
/// rejects anything else, unlike the placeholder strings ("public-key-1"/"-2") these tests used
/// before that validation existed.
const VALID_PUBLIC_KEY_1: &str =
    "BCzG8GfIlqc_jCOKNGc2CvLyWowp3AONLdtlEE3vTlB45AFnm2CpLD6KESfO43K5O_A29tQQLv8w8kmYRTTlyfA";
const VALID_PUBLIC_KEY_2: &str =
    "BNJcDXcjx8aP-iu3VL9t1aQwB-A-rwD20LCXBdU0dK5UnLmljFD60fjdNHOCWlHsamvFT7OkODbXEMhq3HrIszM";

/// A real 32-byte VAPID private key, base64url-no-pad encoded -- lifted from the `web-push`
/// crate's own test fixtures (`vapid::builder::tests::PRIVATE_BASE64`), same as
/// `web_push::tests::VALID_PRIVATE_KEY`.
const VALID_PRIVATE_KEY: &str = "IQ9Ur0ykXoHS9gzfYX0aBjy9lvdrjx_PFUXmie9YRcY";

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
            web_push_config_request(conn, VALID_PUBLIC_KEY_1, VALID_PRIVATE_KEY),
            &admin,
            conn,
        )
        .expect("configure should succeed");

        let web_push_config = updated.web_push_config.expect("web_push_config should be set");
        assert_eq!(web_push_config.public_vapid_key, VALID_PUBLIC_KEY_1);
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
            web_push_config_request(conn, VALID_PUBLIC_KEY_1, VALID_PRIVATE_KEY),
            &admin,
            conn,
        )
        .expect("first configure should succeed");

        // Changing just the public key, with private_vapid_key left blank (as the client always
        // sends it, since it never gets the real value back to resend).
        configure_server(
            web_push_config_request(conn, VALID_PUBLIC_KEY_2, ""),
            &admin,
            conn,
        )
        .expect("second configure should succeed");

        let stored: WebPushConfig = get_server_configuration_model(conn)
            .expect("failed to fetch stored config")
            .web_push_config
            .and_then(|c| serde_json::from_value(c).ok())
            .expect("web_push_config should still be configured");
        assert_eq!(stored.public_vapid_key, VALID_PUBLIC_KEY_2);
        assert_eq!(stored.private_vapid_key, VALID_PRIVATE_KEY);

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
            web_push_config_request(conn, VALID_PUBLIC_KEY_1, VALID_PRIVATE_KEY),
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

#[test]
fn blank_public_vapid_key_is_accepted_when_not_yet_configured() {
    // e.g. `WebPushPrivateKeyEditClicked`'s flow, saving a private key before any public key has
    // ever been set -- `applyWebPushPrivateKey`'s `existingPublicKey` falls back to "" in that
    // case, which shouldn't itself be treated as an invalid value.
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_blank_public_key_ok");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        configure_server(web_push_config_request(conn, "", VALID_PRIVATE_KEY), &admin, conn)
            .expect("configure should succeed");

        Ok(())
    });
}

#[test]
fn malformed_public_vapid_key_is_rejected() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_bad_public_key");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        // Not valid base64url at all.
        let result = configure_server(
            web_push_config_request(conn, "not valid base64url!!!", ""),
            &admin,
            conn,
        );
        assert!(result.is_err());

        Ok(())
    });
}

#[test]
fn wrong_length_public_vapid_key_is_rejected() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_short_public_key");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        // The exact production shape: a public key with a handful of stray trailing characters
        // (swept up from the private key sitting right next to it in `web-push
        // generate-vapid-keys`'s own output), decoding to more than the required 65 bytes.
        let result = configure_server(
            web_push_config_request(
                conn,
                &format!("{VALID_PUBLIC_KEY_1}-FWkr6UwysOygkkDxqo"),
                "",
            ),
            &admin,
            conn,
        );
        assert!(result.is_err());

        Ok(())
    });
}

#[test]
fn malformed_private_vapid_key_is_rejected() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_bad_private_key");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let result = configure_server(
            web_push_config_request(conn, VALID_PUBLIC_KEY_1, "not valid base64url!!!"),
            &admin,
            conn,
        );
        assert!(result.is_err());

        Ok(())
    });
}

#[test]
fn wrong_length_private_vapid_key_is_rejected() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "wpc_short_private_key");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        // Valid base64url, but decodes to fewer than the required 32 bytes.
        let result = configure_server(
            web_push_config_request(conn, VALID_PUBLIC_KEY_1, "AAAAAAAAAAAAAAAAAAAAAA"),
            &admin,
            conn,
        );
        assert!(result.is_err());

        Ok(())
    });
}
