//! Specs for `logic::sync_sources::stellarwp_sync` -- the paginated StellarWP "The Events
//! Calendar" fetch behind a `stellarwp_subscription_endpoint` `SyncSource`. The page-collecting
//! logic is exercised with in-memory pages (no network); the end-to-end specs use
//! `factories::serve_stellarwp_pages`'s local stub server.

use std::sync::atomic::{AtomicU32, Ordering};

use chrono::{DateTime, Duration, Utc};
use diesel::prelude::*;
use diesel::Connection;
use tonic::{Code, Status};

use crate::logic::{
    collect_pages, stellarwp_page_url, sync_source_stellarwp, sync_source_stellarwp_first_page,
    sync_source_text,
};
use crate::models;
use crate::protos::*;
use crate::rpcs::create_sync_source;
use crate::schema::{occasions, posts};
use crate::tests::factories::*;

const ICS_FORMAT: &str = "%Y%m%dT%H%M%SZ";

fn start_in_days(days: i64) -> DateTime<Utc> {
    (Utc::now() + Duration::days(days))
        .date_naive()
        .and_hms_opt(12, 0, 0)
        .unwrap()
        .and_utc()
}

fn vevent(uid: &str, start: DateTime<Utc>) -> String {
    format!(
        "BEGIN:VEVENT\r\nUID:{uid}\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:{uid}\r\nEND:VEVENT\r\n",
        start.format(ICS_FORMAT),
        (start + Duration::hours(1)).format(ICS_FORMAT),
    )
}

/// A page of the feed holding one VEVENT per `(uid, days from now)`.
fn page(events: &[(&str, i64)]) -> String {
    let body: String = events
        .iter()
        .map(|(uid, days)| vevent(uid, start_in_days(*days)))
        .collect();
    format!("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\n{body}END:VCALENDAR\r\n")
}

fn uids(paged: &crate::logic::PagedCalendar) -> Vec<String> {
    let mut uids: Vec<String> = paged
        .calendar
        .iter()
        .filter_map(|component| component.as_event())
        .filter_map(|event| icalendar::Component::property_value(event, "UID"))
        .map(str::to_string)
        .collect();
    uids.sort();
    uids
}

/// Serves `pages[n - 1]` for page `n`, and the plugin's empty "past the end" body after that.
fn serve_in_memory(pages: Vec<String>) -> impl Fn(u32) -> Result<String, Status> + Sync {
    move |n| Ok(pages.get(n as usize - 1).cloned().unwrap_or_default())
}

#[test]
fn collects_every_page_dedupes_overlap_and_stops_at_the_empty_page() {
    let fetch = serve_in_memory(vec![
        page(&[("a", 1), ("b", 2)]),
        // Neighboring pages can overlap: "b" is on both.
        page(&[("b", 2), ("c", 3)]),
        page(&[("d", 4)]),
    ]);

    let paged = collect_pages(40, fetch).expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b", "c", "d"]);
    assert_eq!(paged.coverage_horizon, None, "the feed ended, so it's complete");
}

#[test]
fn stops_at_a_page_with_nothing_new_even_if_the_site_ignores_paged() {
    // A site that ignores `paged` serves the same page forever.
    let fetches = AtomicU32::new(0);
    let same = page(&[("a", 1), ("b", 2)]);
    let paged = collect_pages(40, |_| {
        fetches.fetch_add(1, Ordering::SeqCst);
        Ok(same.clone())
    })
    .expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b"]);
    assert_eq!(paged.coverage_horizon, None);
    assert!(
        fetches.load(Ordering::SeqCst) < 40,
        "should not have walked all 40 pages"
    );
}

#[test]
fn reports_a_coverage_horizon_when_it_hits_the_page_cap() {
    // Every page has a new event, so the feed never ends within 3 pages.
    let paged = collect_pages(3, |n| {
        Ok(page(&[(&format!("e{n}"), n as i64)]))
    })
    .expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["e1", "e2", "e3"]);
    assert_eq!(
        paged.coverage_horizon,
        Some(start_in_days(3)),
        "truncated at the latest event start seen"
    );
}

#[test]
fn a_cap_of_one_page_is_always_truncated() {
    let paged = collect_pages(1, serve_in_memory(vec![page(&[("a", 1), ("b", 5)])]))
        .expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b"]);
    assert_eq!(paged.coverage_horizon, Some(start_in_days(5)));
}

#[test]
fn an_empty_first_page_is_an_error() {
    let err = collect_pages(40, |_| Ok(String::new())).unwrap_err();
    assert_eq!(err.message(), "stellarwp_empty_response");
}

#[test]
fn a_non_calendar_body_is_an_error_not_the_end_of_the_feed() {
    // E.g. a Cloudflare challenge page partway through: must not read as "feed ended", or
    // everything beyond it would look deleted.
    let first = page(&[("a", 1)]);
    let err = collect_pages(40, |n| match n {
        1 => Ok(first.clone()),
        _ => Ok("<!DOCTYPE html><html><title>Just a moment...</title></html>".to_string()),
    })
    .unwrap_err();
    assert_eq!(err.code(), Code::FailedPrecondition);
}

#[test]
fn a_failed_page_fails_the_whole_collect() {
    let first = page(&[("a", 1)]);
    let second = page(&[("b", 2)]);
    let err = collect_pages(40, |n| match n {
        1 => Ok(first.clone()),
        2 => Ok(second.clone()),
        _ => Err(Status::new(Code::FailedPrecondition, "stellarwp_fetch_failed")),
    })
    .unwrap_err();
    assert_eq!(err.message(), "stellarwp_fetch_failed");
}

#[test]
fn a_failure_past_the_end_of_the_feed_is_ignored() {
    // The first batch fetches pages 1-4 at once: page 3 is the end, so page 4's failure (a
    // speculative overshoot) must not matter.
    let first = page(&[("a", 1)]);
    let second = page(&[("b", 2)]);
    let paged = collect_pages(40, |n| match n {
        1 => Ok(first.clone()),
        2 => Ok(second.clone()),
        3 => Ok(String::new()),
        _ => Err(Status::new(Code::FailedPrecondition, "stellarwp_fetch_failed")),
    })
    .expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b"]);
    assert_eq!(paged.coverage_horizon, None);
}

#[test]
fn page_url_sets_paged_and_keeps_the_rest_of_the_query() {
    let endpoint = "https://example.com/?post_type=tribe_events&ical=1&eventDisplay=list&tribe_events_cat=music";

    let first = stellarwp_page_url(endpoint, 1).unwrap();
    assert_eq!(first.query_pairs().find(|(k, _)| k == "paged"), None);
    assert!(first.as_str().contains("post_type=tribe_events"));
    assert!(first.as_str().contains("tribe_events_cat=music"));

    let third = stellarwp_page_url(endpoint, 3).unwrap();
    let paged: Vec<_> = third.query_pairs().filter(|(k, _)| k == "paged").collect();
    assert_eq!(paged.len(), 1);
    assert_eq!(paged[0].1, "3");
    assert!(third.as_str().contains("ical=1"));
}

#[test]
fn page_url_replaces_an_existing_paged_param() {
    let url = stellarwp_page_url("https://example.com/?ical=1&paged=7", 2).unwrap();
    let paged: Vec<_> = url.query_pairs().filter(|(k, _)| k == "paged").collect();
    assert_eq!(paged.len(), 1);
    assert_eq!(paged[0].1, "2");

    let url = stellarwp_page_url("https://example.com/?ical=1&paged=7", 1).unwrap();
    assert_eq!(url.query_pairs().find(|(k, _)| k == "paged"), None);
}

#[test]
fn page_url_rejects_non_http_urls() {
    for bad in ["", "not a url", "ftp://example.com/cal", "file:///etc/passwd", "javascript:alert(1)"] {
        let err = stellarwp_page_url(bad, 1).unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument, "{bad:?}");
        assert_eq!(err.message(), "stellarwp_subscription_endpoint_invalid");
    }
}

fn synced_occasions(
    conn: &mut crate::db_connection::PgPooledConnection,
    source_id: i64,
) -> Vec<(String, models::Occasion)> {
    let mut found: Vec<(String, models::Occasion)> = occasions::table
        .inner_join(posts::table.on(posts::id.eq(occasions::post_id)))
        .select((posts::sync_source_uid, models::OCCASION_COLUMNS))
        .filter(posts::sync_source_id.eq(source_id))
        .load::<(Option<String>, models::Occasion)>(conn)
        .unwrap()
        .into_iter()
        .map(|(uid, occasion)| (uid.unwrap(), occasion))
        .collect();
    found.sort_by(|a, b| a.0.cmp(&b.0));
    found
}

#[test]
fn syncs_events_from_every_page_end_to_end() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_all_pages");
        let url = serve_stellarwp_pages(vec![
            page(&[("a", 1), ("b", 2)]),
            page(&[("b", 2), ("c", 3)]),
            page(&[("d", 4)]),
        ]);
        let source = create_stellarwp_sync_source_row(conn, &user, &url);

        sync_source_stellarwp(&source, conn).expect("sync should succeed");

        let synced = synced_occasions(conn, source.id);
        let synced_uids: Vec<&str> = synced.iter().map(|(uid, _)| uid.as_str()).collect();
        assert_eq!(synced_uids, vec!["a", "b", "c", "d"]);
        assert_eq!(
            models::get_sync_source(source.id, conn)?.occasion_count,
            4,
            "the overlapping event must not be created twice"
        );

        Ok(())
    });
}

#[test]
fn first_page_sync_only_fetches_page_one_and_does_not_prune_the_rest() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_first_page");
        let pages = vec![
            page(&[("a", 1), ("b", 2)]),
            page(&[("c", 10)]),
            page(&[("d", 20)]),
        ];
        let url = serve_stellarwp_pages(pages.clone());
        let source = create_stellarwp_sync_source_row(conn, &user, &url);

        // Full sync first, so c and d exist.
        sync_source_stellarwp(&source, conn).expect("full sync should succeed");
        assert_eq!(synced_occasions(conn, source.id).len(), 4);

        // The first-page-only sync sees just a and b -- c and d weren't fetched, which isn't the
        // same as having disappeared, so they must not be marked missing.
        sync_source_stellarwp_first_page(&source, conn).expect("first-page sync should succeed");
        for (uid, occasion) in synced_occasions(conn, source.id) {
            assert!(
                occasion.sync_missing_since.is_none(),
                "{uid} was beyond the first page's coverage and must not be marked missing"
            );
        }

        // Whereas the same page-1-only content as a *complete* feed does mark c and d missing.
        sync_source_text(&source, &pages[0], conn).expect("plain sync should succeed");
        for (uid, occasion) in synced_occasions(conn, source.id) {
            let expect_missing = uid == "c" || uid == "d";
            assert_eq!(
                occasion.sync_missing_since.is_some(),
                expect_missing,
                "{uid}"
            );
        }

        Ok(())
    });
}

#[test]
fn a_failing_page_fails_the_sync_without_pruning_anything() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_failing_page");
        let url = serve_stellarwp_pages(vec![page(&[("a", 1)]), page(&[("b", 2)])]);
        let source = create_stellarwp_sync_source_row(conn, &user, &url);
        sync_source_stellarwp(&source, conn).expect("initial sync should succeed");

        // Same source, but the 2nd page is now a non-calendar body: the sync must fail outright.
        let broken = serve_stellarwp_pages(vec![
            page(&[("a", 1)]),
            "<html>Just a moment...</html>".to_string(),
        ]);
        let source = models::SyncSource {
            configuration: serde_json::json!({ "stellarwp_subscription_endpoint": broken }),
            ..source
        };
        assert!(sync_source_stellarwp(&source, conn).is_err());
        for (uid, occasion) in synced_occasions(conn, source.id) {
            assert!(occasion.sync_missing_since.is_none(), "{uid}");
        }

        Ok(())
    });
}

fn stellarwp_request(endpoint: &str) -> SyncSource {
    SyncSource {
        configuration: Some(sync_source::Configuration::StellarwpSubscriptionEndpoint(
            endpoint.to_string(),
        )),
        ..Default::default()
    }
}

#[test]
fn create_requires_sync_events_from_ics_permission() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_create_noperm");

        let err = create_sync_source(
            stellarwp_request("https://example.invalid/?post_type=tribe_events&ical=1"),
            &user,
            conn,
        )
        .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "permission_SYNC_EVENTS_FROM_ICS_required");

        Ok(())
    });
}

#[test]
fn create_rejects_an_invalid_endpoint() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_create_badurl");
        let user = grant_permissions(conn, &user, vec![Permission::SyncEventsFromIcs]);

        let err = create_sync_source(stellarwp_request("ftp://example.invalid/cal"), &user, conn)
            .unwrap_err();
        assert_eq!(err.code(), Code::InvalidArgument);
        assert_eq!(err.message(), "stellarwp_subscription_endpoint_invalid");

        let err = create_sync_source(stellarwp_request("   "), &user, conn).unwrap_err();
        assert_eq!(err.message(), "subscription_url_required");

        Ok(())
    });
}
