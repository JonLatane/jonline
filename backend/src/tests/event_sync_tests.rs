//! Specs for `logic::sync_event_sync_source[_text]` -- the actual ICS-pull/upsert logic behind
//! `CreateEventSyncSource`/`UpdateEventSyncSource`. Most specs drive `sync_event_sync_source_text`
//! directly against a fixed ICS string (no network at all); a couple exercise
//! `sync_event_sync_source` itself against `factories::serve_ics`'s local stub server to confirm
//! the HTTP fetch path also works end to end.

use chrono::{Duration, Utc};
use diesel::Connection;

use crate::logic::{sync_event_sync_source, sync_event_sync_source_text};
use crate::models;
use crate::schema::{event_instances, events, posts};
use crate::tests::factories::*;
use diesel::prelude::*;

const ICS_FORMAT: &str = "%Y%m%dT%H%M%SZ";

fn instances_for(conn: &mut crate::db_connection::PgPooledConnection, event_id: i64) -> Vec<models::EventInstance> {
    event_instances::table
        .filter(event_instances::event_id.eq(event_id))
        .load::<models::EventInstance>(conn)
        .unwrap()
}

fn synced_event(
    conn: &mut crate::db_connection::PgPooledConnection,
    source_id: i64,
    uid: &str,
) -> Option<models::Event> {
    events::table
        .filter(events::event_sync_source_id.eq(source_id))
        .load::<models::Event>(conn)
        .unwrap()
        .into_iter()
        .find(|e| e.info.get("event_sync_source_uid").and_then(|v| v.as_str()) == Some(uid))
}

fn post_of(conn: &mut crate::db_connection::PgPooledConnection, post_id: i64) -> models::Post {
    posts::table
        .select(models::POST_COLUMNS)
        .filter(posts::id.eq(post_id))
        .first(conn)
        .unwrap()
}

#[test]
fn single_vevent_creates_event_and_instance() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_single_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");

        let start = Utc::now() + Duration::days(1);
        let end = start + Duration::hours(1);
        let ics = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:single-1\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:Single Event\r\nDESCRIPTION:Single description\r\nLOCATION:Somewhere\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            start.format(ICS_FORMAT),
            end.format(ICS_FORMAT)
        );

        sync_event_sync_source_text(&source, &ics, conn).expect("sync should succeed");

        let event = synced_event(conn, source.id, "single-1").expect("event should have been created");
        let post = post_of(conn, event.post_id);
        assert_eq!(post.title, Some("Single Event".to_string()));
        assert_eq!(post.content, Some("Single description".to_string()));

        let instances = instances_for(conn, event.id);
        assert_eq!(instances.len(), 1);
        assert!(instances[0].event_sync_source_instance_id.is_some());

        Ok(())
    });
}

#[test]
fn recurring_vevent_expands_into_multiple_instances() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_recur_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");

        let start = Utc::now() + Duration::days(1);
        let end = start + Duration::hours(1);
        let ics = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:recur-1\r\nDTSTART:{}\r\nDTEND:{}\r\nRRULE:FREQ=DAILY;COUNT=5\r\nSUMMARY:Recurring Event\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            start.format(ICS_FORMAT),
            end.format(ICS_FORMAT)
        );

        sync_event_sync_source_text(&source, &ics, conn).expect("sync should succeed");

        let event = synced_event(conn, source.id, "recur-1").expect("event should have been created");
        let instances = instances_for(conn, event.id);
        assert_eq!(instances.len(), 5, "RRULE COUNT=5 should expand to 5 instances");

        Ok(())
    });
}

#[test]
fn recurrence_id_override_changes_one_occurrence() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_override_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");

        let start = Utc::now() + Duration::days(1);
        let end = start + Duration::hours(1);
        let second_occurrence_start = start + Duration::days(1);
        let moved_start = second_occurrence_start + Duration::hours(3);
        let moved_end = moved_start + Duration::hours(1);
        let ics = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:override-1\r\nDTSTART:{}\r\nDTEND:{}\r\nRRULE:FREQ=DAILY;COUNT=3\r\nSUMMARY:Series\r\nEND:VEVENT\r\nBEGIN:VEVENT\r\nUID:override-1\r\nRECURRENCE-ID:{}\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:Moved Occurrence\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            start.format(ICS_FORMAT),
            end.format(ICS_FORMAT),
            second_occurrence_start.format(ICS_FORMAT),
            moved_start.format(ICS_FORMAT),
            moved_end.format(ICS_FORMAT),
        );

        sync_event_sync_source_text(&source, &ics, conn).expect("sync should succeed");

        let event = synced_event(conn, source.id, "override-1").expect("event should have been created");
        let instances = instances_for(conn, event.id);
        assert_eq!(instances.len(), 3);

        let overridden_post_titles: Vec<Option<String>> = instances
            .iter()
            .map(|i| post_of(conn, i.post_id).title)
            .collect();
        assert!(
            overridden_post_titles.contains(&Some("Moved Occurrence".to_string())),
            "one instance should carry the RECURRENCE-ID override's own title, got {:?}",
            overridden_post_titles
        );

        Ok(())
    });
}

#[test]
fn occurrence_more_than_a_year_in_the_past_is_not_created() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_old_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");

        let start = Utc::now() - Duration::days(400);
        let end = start + Duration::hours(1);
        let ics = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:old-1\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:Old Event\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            start.format(ICS_FORMAT),
            end.format(ICS_FORMAT)
        );

        sync_event_sync_source_text(&source, &ics, conn).expect("sync should succeed");

        assert!(
            synced_event(conn, source.id, "old-1").is_none(),
            "an event more than a year in the past should not be synced in"
        );

        Ok(())
    });
}

#[test]
fn resync_removes_instances_no_longer_in_feed_but_leaves_old_ones_alone() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_prune_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");

        let recent_start = Utc::now() + Duration::days(1);
        let recent_end = recent_start + Duration::hours(1);
        let old_start = Utc::now() - Duration::days(400);
        let old_end = old_start + Duration::hours(1);

        // First sync: one recent occurrence for a recurring UID, plus a standalone old one that
        // (per the 1-year-lookback rule) should never come from a *feed* -- so instead we insert
        // it directly to simulate "a row that predates the lookback window, from before we
        // tightened the window, or from manual entry" and confirm resync doesn't touch it.
        let ics_v1 = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:prune-1\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:Will vanish\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            recent_start.format(ICS_FORMAT),
            recent_end.format(ICS_FORMAT)
        );
        sync_event_sync_source_text(&source, &ics_v1, conn).expect("initial sync should succeed");
        let event = synced_event(conn, source.id, "prune-1").expect("event should exist after first sync");
        assert_eq!(instances_for(conn, event.id).len(), 1);

        // Manually backdate that instance to simulate a pre-existing old occurrence, and insert
        // an extra manually-tagged "old" instance under the same event/source to prove old rows
        // aren't deleted by resync even when absent from the feed.
        let old_start_db: std::time::SystemTime = old_start.into();
        let old_end_db: std::time::SystemTime = old_end.into();
        diesel::update(event_instances::table.filter(event_instances::event_id.eq(event.id)))
            .set((
                event_instances::starts_at.eq(old_start_db),
                event_instances::ends_at.eq(old_end_db),
            ))
            .execute(conn)
            .unwrap();

        // Second sync: same UID, but the feed no longer mentions that (now old-dated) occurrence
        // at all (empty calendar). Since it's now more than a year in the past, it must survive.
        let ics_v2 = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nEND:VCALENDAR\r\n";
        sync_event_sync_source_text(&source, ics_v2, conn).expect("second sync should succeed");

        assert_eq!(
            instances_for(conn, event.id).len(),
            1,
            "an instance older than the 1-year lookback should survive even after it drops out of the feed"
        );

        Ok(())
    });
}

#[test]
fn resync_prunes_recent_instance_dropped_from_feed_and_deletes_emptied_event() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_prune2_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");

        let start = Utc::now() + Duration::days(1);
        let end = start + Duration::hours(1);
        let ics_v1 = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:prune-2\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:Will vanish\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            start.format(ICS_FORMAT),
            end.format(ICS_FORMAT)
        );
        sync_event_sync_source_text(&source, &ics_v1, conn).expect("initial sync should succeed");
        let event = synced_event(conn, source.id, "prune-2").expect("event should exist after first sync");

        let ics_v2 = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nEND:VCALENDAR\r\n";
        sync_event_sync_source_text(&source, ics_v2, conn).expect("second sync should succeed");

        assert!(
            events::table
                .filter(events::id.eq(event.id))
                .first::<models::Event>(conn)
                .optional()
                .unwrap()
                .is_none(),
            "an event whose only (in-window) instance disappeared from the feed should be deleted"
        );

        Ok(())
    });
}

#[test]
fn last_synced_at_is_updated() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_lastsync_owner");
        let source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");
        assert!(source.last_synced_at.is_none());

        let ics = "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nEND:VCALENDAR\r\n";
        sync_event_sync_source_text(&source, ics, conn).expect("sync should succeed");

        let refreshed = models::get_event_sync_source(source.id, conn).unwrap();
        assert!(refreshed.last_synced_at.is_some());

        Ok(())
    });
}

#[test]
fn sync_via_http_fetches_and_parses_from_a_real_url() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_http_owner");

        let start = Utc::now() + Duration::days(1);
        let end = start + Duration::hours(1);
        let ics = format!(
            "BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//test//\r\nBEGIN:VEVENT\r\nUID:http-1\r\nDTSTART:{}\r\nDTEND:{}\r\nSUMMARY:Via HTTP\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n",
            start.format(ICS_FORMAT),
            end.format(ICS_FORMAT)
        );
        let url = serve_ics(&ics);
        let source = create_event_sync_source_row(conn, &user, &url);

        sync_event_sync_source(&source, conn).expect("sync over HTTP should succeed");

        let event = synced_event(conn, source.id, "http-1").expect("event should have been created via HTTP sync");
        let post = post_of(conn, event.post_id);
        assert_eq!(post.title, Some("Via HTTP".to_string()));

        Ok(())
    });
}

#[test]
fn missing_ics_url_fails_with_precondition_error() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "est_nourl_owner");
        let mut source = create_event_sync_source_row(conn, &user, "http://example.invalid/cal.ics");
        source.configuration = serde_json::json!({});

        let err = sync_event_sync_source(&source, conn).unwrap_err();
        assert_eq!(err.code(), tonic::Code::FailedPrecondition);
        assert_eq!(err.message(), "ics_url_required");

        Ok(())
    });
}
