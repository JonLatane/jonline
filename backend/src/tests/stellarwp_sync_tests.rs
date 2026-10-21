//! Specs for `logic::sync_sources::stellarwp_sync` -- the paginated StellarWP "The Events
//! Calendar" fetch behind a `stellarwp_ics_subscription_url` `SyncSource`. The page-collecting
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
fn collects_the_whole_feed_when_each_page_overlaps_the_last_by_most_of_its_length() {
    // The real plugin's shape: `paged` steps through the list 12 events at a time (the site's
    // "events per page" display setting) while each iCal response is 30 events long -- so with 50
    // events in total, page n holds events [12(n-1), 12(n-1) + 30).
    let events: Vec<(String, i64)> = (0..50).map(|i| (format!("e{i:02}"), 1 + i as i64)).collect();
    let fetch = |n: u32| -> Result<String, Status> {
        let from = 12 * (n as usize - 1);
        if from >= events.len() {
            return Ok(String::new());
        }
        let slice: Vec<(&str, i64)> = events[from..(from + 30).min(events.len())]
            .iter()
            .map(|(uid, days)| (uid.as_str(), *days))
            .collect();
        Ok(page(&slice))
    };

    let paged = collect_pages(80, fetch).expect("collect should succeed");

    let expected: Vec<String> = (0..50).map(|i| format!("e{i:02}")).collect();
    assert_eq!(uids(&paged), expected);
    assert_eq!(paged.coverage_horizon, None);
}

#[test]
fn a_site_that_ignores_paged_is_truncated_not_complete() {
    // A site that ignores `paged` serves the same page forever. Stops fetching, but a repeated page
    // doesn't prove nothing lies beyond it -- so the feed must stay treated as truncated.
    let fetches = AtomicU32::new(0);
    let same = page(&[("a", 1), ("b", 2)]);
    let paged = collect_pages(80, |_| {
        fetches.fetch_add(1, Ordering::SeqCst);
        Ok(same.clone())
    })
    .expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b"]);
    assert_eq!(paged.coverage_horizon, Some(start_in_days(2)));
    assert!(
        fetches.load(Ordering::SeqCst) < 80,
        "should not have walked all 80 pages"
    );
}

#[test]
fn a_short_feed_whose_tail_repeats_before_the_empty_page_is_still_complete() {
    // Like trianglefarms.com: 13 events fit on page 1, page 2 repeats the tail, page 3 is empty.
    let fetch = serve_in_memory(vec![
        page(&[("a", 1), ("b", 2), ("c", 3)]),
        page(&[("c", 3)]),
    ]);

    let paged = collect_pages(80, fetch).expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b", "c"]);
    assert_eq!(paged.coverage_horizon, None, "the empty page proved the end");
}

#[test]
fn a_repeated_page_right_before_a_batch_boundary_is_probed_for_the_end() {
    // Pages 1-4 are the first batch; page 4 repeats page 3, and the empty page is page 5 (next
    // batch) -- the probe after the stall must still find it.
    let fetch = serve_in_memory(vec![
        page(&[("a", 1)]),
        page(&[("a", 1), ("b", 2)]),
        page(&[("b", 2), ("c", 3)]),
        page(&[("c", 3)]),
    ]);

    let paged = collect_pages(80, fetch).expect("collect should succeed");

    assert_eq!(uids(&paged), vec!["a", "b", "c"]);
    assert_eq!(paged.coverage_horizon, None);
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
        assert_eq!(err.message(), "stellarwp_ics_subscription_url_invalid");
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
fn events_that_have_ended_are_kept_when_they_drop_out_of_the_upcoming_only_feed() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_keeps_past");
        let url = serve_stellarwp_pages(vec![page(&[("upcoming-1", 3)])]);
        let source = create_stellarwp_sync_source_row(conn, &user, &url);

        // Previously synced: one event that has since ended, one still to come, and a third
        // still to come that the feed is about to stop listing.
        sync_source_text(
            &source,
            &page(&[("ended", -2), ("upcoming-1", 3), ("cancelled", 5)]),
            conn,
        )
        .expect("initial sync should succeed");
        assert_eq!(synced_occasions(conn, source.id).len(), 3);

        // The Events Calendar's list view only lists upcoming events: "ended" is gone from it
        // simply because it's over, and "cancelled" is gone because it was really removed.
        sync_source_stellarwp(&source, conn).expect("sync should succeed");

        for (uid, occasion) in synced_occasions(conn, source.id) {
            assert_eq!(
                occasion.sync_missing_since.is_some(),
                uid == "cancelled",
                "{uid}: only the event that's still upcoming but no longer listed counts as missing"
            );
        }

        // Even once the grace period is long over, the ended event survives.
        diesel::update(occasions::table)
            .set(occasions::sync_missing_since.eq(
                std::time::SystemTime::now() - std::time::Duration::from_secs(30 * 24 * 3600),
            ))
            .filter(occasions::sync_missing_since.is_not_null())
            .execute(conn)
            .unwrap();
        sync_source_stellarwp(&source, conn).expect("sync should succeed");
        let remaining: Vec<String> = synced_occasions(conn, source.id)
            .into_iter()
            .map(|(uid, _)| uid)
            .collect();
        assert_eq!(remaining, vec!["ended", "upcoming-1"]);

        Ok(())
    });
}

#[test]
fn an_occasion_tied_with_the_coverage_horizon_is_not_pruned() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_tied_horizon");
        // Pages are cut off after the first, which ends with "b"; "c" starts at the very same
        // time as "b" and may simply be on the next page.
        let url = serve_stellarwp_pages(vec![page(&[("a", 1), ("b", 5)])]);
        let source = create_stellarwp_sync_source_row(conn, &user, &url);
        sync_source_text(&source, &page(&[("a", 1), ("b", 5), ("c", 5), ("d", 9)]), conn)
            .expect("initial sync should succeed");

        sync_source_stellarwp_first_page(&source, conn).expect("first-page sync should succeed");

        for (uid, occasion) in synced_occasions(conn, source.id) {
            assert!(
                occasion.sync_missing_since.is_none(),
                "{uid} starts at or after the horizon and must not be marked missing"
            );
        }

        Ok(())
    });
}

#[test]
fn a_site_that_ignores_paged_does_not_prune_what_it_never_showed() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_ignores_paged");
        // Every page is the same one.
        let url = serve_stellarwp_pages(vec![page(&[("a", 1), ("b", 2)]); 100]);
        let source = create_stellarwp_sync_source_row(conn, &user, &url);
        sync_source_text(&source, &page(&[("a", 1), ("b", 2), ("later", 20)]), conn)
            .expect("initial sync should succeed");

        sync_source_stellarwp(&source, conn).expect("sync should succeed");

        for (uid, occasion) in synced_occasions(conn, source.id) {
            assert!(
                occasion.sync_missing_since.is_none(),
                "{uid}: a repeated page isn't proof the feed has nothing later"
            );
        }

        Ok(())
    });
}

#[test]
fn a_sync_for_a_since_edited_configuration_discards_what_it_fetched() {
    let mut conn = test_conn();
    conn.test_transaction::<_, Status, _>(|conn| {
        let user = create_user(conn, "swp_edited_midsync");
        let old_url = serve_stellarwp_pages(vec![page(&[("old-event", 1)])]);
        let new_url = serve_stellarwp_pages(vec![page(&[("new-event", 1)])]);
        let source = create_stellarwp_sync_source_row(conn, &user, &old_url);

        // The source is edited (to the new URL) after `source` was loaded but before its sync
        // gets to save anything -- a sync for the old configuration must not write its events.
        diesel::update(crate::schema::sync_sources::table.filter(crate::schema::sync_sources::id.eq(source.id)))
            .set(crate::schema::sync_sources::configuration.eq(
                serde_json::json!({ "stellarwp_ics_subscription_url": new_url }),
            ))
            .execute(conn)
            .unwrap();

        let err = sync_source_stellarwp(&source, conn).unwrap_err();
        assert_eq!(err.code(), Code::Aborted);
        assert_eq!(err.message(), "sync_source_changed");
        assert!(synced_occasions(conn, source.id).is_empty());

        // The current configuration syncs fine.
        let current = models::get_sync_source(source.id, conn)?;
        sync_source_stellarwp(&current, conn).expect("sync should succeed");
        let uids: Vec<String> = synced_occasions(conn, source.id)
            .into_iter()
            .map(|(uid, _)| uid)
            .collect();
        assert_eq!(uids, vec!["new-event"]);

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
            configuration: serde_json::json!({ "stellarwp_ics_subscription_url": broken }),
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
        configuration: Some(sync_source::Configuration::StellarwpIcsSubscriptionUrl(
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
        assert_eq!(err.message(), "stellarwp_ics_subscription_url_invalid");

        let err = create_sync_source(stellarwp_request("   "), &user, conn).unwrap_err();
        assert_eq!(err.message(), "subscription_url_required");

        Ok(())
    });
}
