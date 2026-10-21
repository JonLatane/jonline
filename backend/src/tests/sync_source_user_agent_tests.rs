//! Specs for `SyncSource.user_agent` -- the `User-Agent` header a source's fetches send (some feeds
//! sit behind bot protection that only admits certain clients, e.g. raleighnc.gov admits `curl/*`).
//! Fetches are checked against `factories::serve_stellarwp_pages_recording_user_agents`'s local
//! stub, which records what each request sent.

use diesel::prelude::*;
use diesel::Connection;
use tonic::{Code, Status};

use crate::logic::{sync_source, sync_source_stellarwp};
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::{create_sync_source, update_sync_source};
use crate::schema::sync_sources;
use crate::tests::factories::*;

const EMPTY_ICS: &str = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nEND:VCALENDAR\r\n";
const EMPTY_RSS: &str = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><rss version=\"2.0\"><channel><title>Test</title><link>http://example.invalid/</link><description>Test</description></channel></rss>";
const RELLM_UA: &str = "Rellm-SyncSource/1.0 (+https://rellm.org)";
const CURL_UA: &str = "curl/8.7.1";

fn with_user_agent(
    conn: &mut crate::db_connection::PgPooledConnection,
    source: models::SyncSource,
    user_agent: &str,
) -> models::SyncSource {
    diesel::update(sync_sources::table.filter(sync_sources::id.eq(source.id)))
        .set(sync_sources::user_agent.eq(user_agent))
        .get_result(conn)
        .expect("failed to set user_agent")
}

fn recorded(user_agents: &std::sync::Arc<std::sync::Mutex<Vec<Option<String>>>>) -> Vec<Option<String>> {
    user_agents.lock().unwrap().clone()
}

#[test]
fn an_ics_fetch_sends_the_selected_user_agent() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "ua_ics");
        for (setting, expected) in [
            ("NO_USER_AGENT", None),
            ("RELLM", Some(RELLM_UA)),
            ("CURL", Some(CURL_UA)),
        ] {
            let (url, seen) = serve_stellarwp_pages_recording_user_agents(vec![EMPTY_ICS.to_string()]);
            let source = create_sync_source_row(conn, &user, &url);
            let source = with_user_agent(conn, source, setting);

            sync_source(&source, conn).expect("sync should succeed");

            assert_eq!(
                recorded(&seen),
                vec![expected.map(str::to_string)],
                "user_agent {setting}"
            );
        }
        Ok(())
    });
}

#[test]
fn a_feed_fetch_sends_the_selected_user_agent() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "ua_feed");
        let (url, seen) = serve_stellarwp_pages_recording_user_agents(vec![EMPTY_RSS.to_string()]);
        let source = create_feed_sync_source_row(conn, &user, &url);
        let source = with_user_agent(conn, source, "CURL");

        sync_source(&source, conn).expect("sync should succeed");

        assert_eq!(recorded(&seen), vec![Some(CURL_UA.to_string())]);
        Ok(())
    });
}

#[test]
fn every_stellarwp_page_fetch_sends_the_selected_user_agent() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "ua_stellarwp");
        let (url, seen) = serve_stellarwp_pages_recording_user_agents(vec![
            EMPTY_ICS.to_string(),
            EMPTY_ICS.to_string(),
        ]);
        let source = create_stellarwp_sync_source_row(conn, &user, &url);
        let source = with_user_agent(conn, source, "RELLM");

        sync_source_stellarwp(&source, conn).expect("sync should succeed");

        let seen = recorded(&seen);
        assert!(seen.len() >= 2, "should have fetched several pages, got {seen:?}");
        assert!(
            seen.iter().all(|ua| ua.as_deref() == Some(RELLM_UA)),
            "{seen:?}"
        );
        Ok(())
    });
}

#[test]
fn create_stores_and_returns_the_user_agent_and_defaults_to_none() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "ua_create");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsFromIcs]);
        let url = serve_ics(EMPTY_ICS);

        let created = create_sync_source(
            SyncSource {
                configuration: Some(sync_source::Configuration::IcsSubscriptionUrl(url.clone())),
                user_agent: Some(SyncSourceUserAgent::Curl as i32),
                ..Default::default()
            },
            &user,
            conn,
        )?;
        assert_eq!(created.user_agent, Some(SyncSourceUserAgent::Curl as i32));
        let id = created.id.to_db_id_or_err("id")?;
        assert_eq!(models::get_sync_source(id, conn)?.user_agent, "CURL");

        let defaulted = create_sync_source(
            SyncSource {
                configuration: Some(sync_source::Configuration::IcsSubscriptionUrl(url)),
                ..Default::default()
            },
            &user,
            conn,
        )?;
        assert_eq!(
            defaulted.user_agent,
            Some(SyncSourceUserAgent::NoUserAgent as i32)
        );

        Ok(())
    });
}

#[test]
fn create_rejects_an_unknown_user_agent() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "ua_create_bad");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsFromIcs]);

        let err = create_sync_source(
            SyncSource {
                configuration: Some(sync_source::Configuration::IcsSubscriptionUrl(serve_ics(EMPTY_ICS))),
                user_agent: Some(99),
                ..Default::default()
            },
            &user,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "invalid_user_agent");

        Ok(())
    });
}

#[test]
fn update_changes_the_user_agent_only_when_one_is_sent() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "ua_update");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsFromIcs]);
        let source = create_sync_source_row(conn, &user, &serve_ics(EMPTY_ICS));
        let id = source.id.to_proto_id();

        let updated = update_sync_source(
            SyncSource {
                id: id.clone(),
                user_agent: Some(SyncSourceUserAgent::Rellm as i32),
                ..Default::default()
            },
            &user,
            conn,
        )?;
        assert_eq!(updated.user_agent, Some(SyncSourceUserAgent::Rellm as i32));
        assert_eq!(models::get_sync_source(source.id, conn)?.user_agent, "RELLM");

        // An update that says nothing about it (just bumping the interval) leaves it alone.
        let updated = update_sync_source(
            SyncSource {
                id: id.clone(),
                sync_interval_seconds: 900,
                ..Default::default()
            },
            &user,
            conn,
        )?;
        assert_eq!(updated.user_agent, Some(SyncSourceUserAgent::Rellm as i32));

        // And "No User Agent" is an explicit choice that does take effect.
        let updated = update_sync_source(
            SyncSource {
                id,
                user_agent: Some(SyncSourceUserAgent::NoUserAgent as i32),
                ..Default::default()
            },
            &user,
            conn,
        )?;
        assert_eq!(updated.user_agent, Some(SyncSourceUserAgent::NoUserAgent as i32));

        Ok(())
    });
}
