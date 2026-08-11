//! Specs for `ConfigureServer`'s handling of `FederationInfo.facebook_auth_config.app_secret`:
//! it's write-only (never sent back to a client) and an empty incoming value is a deliberate
//! no-op rather than a clear (see `configure_server`'s own doc comment). Everything else about
//! `ConfigureServer` is exercised incidentally by other RPC specs' setup, not tested here.

use diesel::Connection;

use crate::db_connection::PgPooledConnection;
use crate::logic::server_facebook_app_credentials;
use crate::protos::*;
use crate::rpcs::{configure_server, get_server_configuration_proto};
use crate::tests::factories::*;

/// `configure_server` (like every real caller -- see `validate_configuration`'s
/// `people_settings.unwrap()`) expects a *fully populated* `ServerConfiguration`, not a
/// partial one -- real clients always fetch-then-mutate (mirrors the Elm frontend's
/// `AccountsPanel.updateServerConfig`), so specs do too rather than building a bare one by hand.
fn facebook_auth_request(
    conn: &mut PgPooledConnection,
    app_id: &str,
    app_secret: &str,
) -> ServerConfiguration {
    let mut config = get_server_configuration_proto(conn).expect("failed to fetch base config");
    config.federation_info = Some(FederationInfo {
        servers: config
            .federation_info
            .map(|f| f.servers)
            .unwrap_or_default(),
        facebook_auth_config: Some(FacebookAuthConfig {
            app_id: app_id.to_string(),
            app_secret: app_secret.to_string(),
        }),
    });
    config
}

#[test]
fn app_secret_is_never_returned_to_the_client() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "cst_secret_hidden");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        let updated = configure_server(
            facebook_auth_request(conn, "app-1", "super-secret"),
            &admin,
            conn,
        )
        .expect("configure should succeed");

        let facebook_auth_config = updated
            .federation_info
            .expect("federation_info should be set")
            .facebook_auth_config
            .expect("facebook_auth_config should be set");
        assert_eq!(facebook_auth_config.app_id, "app-1");
        assert_eq!(facebook_auth_config.app_secret, "");

        Ok(())
    });
}

#[test]
fn empty_app_secret_preserves_the_previously_stored_one() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "cst_secret_preserved");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        configure_server(
            facebook_auth_request(conn, "app-1", "super-secret"),
            &admin,
            conn,
        )
        .expect("first configure should succeed");

        // Changing just the App ID, with app_secret left blank (as the client always sends it,
        // since it never gets the real value back to resend).
        configure_server(facebook_auth_request(conn, "app-2", ""), &admin, conn)
            .expect("second configure should succeed");

        let (app_id, app_secret) =
            server_facebook_app_credentials(conn).expect("credentials should still be configured");
        assert_eq!(app_id, "app-2");
        assert_eq!(app_secret, "super-secret");

        Ok(())
    });
}

#[test]
fn setting_facebook_auth_config_to_none_clears_the_stored_secret() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let admin = create_user(conn, "cst_secret_cleared");
        let admin = grant_permissions(conn, &admin, vec![Permission::Admin]);

        configure_server(
            facebook_auth_request(conn, "app-1", "super-secret"),
            &admin,
            conn,
        )
        .expect("first configure should succeed");

        let mut clearing_config =
            get_server_configuration_proto(conn).expect("failed to fetch base config");
        clearing_config.federation_info = clearing_config.federation_info.map(|f| FederationInfo {
            servers: f.servers,
            facebook_auth_config: None,
        });
        configure_server(clearing_config, &admin, conn).expect("clearing configure should succeed");

        let err = server_facebook_app_credentials(conn).unwrap_err();
        assert_eq!(err.message(), "facebook_app_not_configured");

        Ok(())
    });
}
