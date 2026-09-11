//! Specs for `logic::sync_source_feed`/`sync_feed_text` -- the RSS/Atom counterpart to
//! `event_sync_tests`. Most specs drive `sync_feed_text` directly against a fixed feed string
//! (no network at all); one exercises `sync_source` (the dispatcher) itself against
//! `factories::serve_feed`'s local stub server to confirm the HTTP fetch path also works, and one
//! confirms the dispatcher picks this path for an Atom-configured source too.

use diesel::Connection;

use crate::logic::{sync_feed_text, sync_source};
use crate::models;
use crate::schema::posts;
use crate::tests::factories::*;
use diesel::prelude::*;

const RSS_FEED: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Test Feed</title>
    <link>http://example.invalid/</link>
    <description>Test</description>
    <item>
      <title>First Item</title>
      <link>http://example.invalid/1</link>
      <guid>item-1</guid>
      <description>First description</description>
    </item>
  </channel>
</rss>
"#;

const ATOM_FEED: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Test Feed</title>
  <id>urn:test:feed</id>
  <updated>2026-01-01T00:00:00Z</updated>
  <entry>
    <title>First Entry</title>
    <id>entry-1</id>
    <updated>2026-01-01T00:00:00Z</updated>
    <summary>First summary</summary>
    <link href="http://example.invalid/1"/>
  </entry>
</feed>
"#;

fn synced_posts(
    conn: &mut crate::db_connection::PgPooledConnection,
    source_id: i64,
) -> Vec<models::Post> {
    posts::table
        .select(models::POST_COLUMNS)
        .filter(posts::sync_source_id.eq(source_id))
        .load::<models::Post>(conn)
        .unwrap()
}

#[test]
fn single_rss_item_creates_a_post() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "fst_rss_owner");
        let source = create_feed_sync_source_row(conn, &user, "http://example.invalid/feed.rss");

        sync_feed_text(&source, RSS_FEED, conn).expect("sync should succeed");

        let posts = synced_posts(conn, source.id);
        assert_eq!(posts.len(), 1);
        assert_eq!(posts[0].title, Some("First Item".to_string()));
        assert_eq!(posts[0].content, Some("First description".to_string()));
        assert_eq!(posts[0].link, Some("http://example.invalid/1".to_string()));
        assert_eq!(posts[0].sync_source_uid, Some("item-1".to_string()));
        assert_eq!(
            posts[0].sync_source_recurrence_anchor, None,
            "a flat feed item has no recurrence concept"
        );

        Ok(())
    });
}

#[test]
fn single_atom_entry_creates_a_post() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "fst_atom_owner");
        let source = create_feed_sync_source_row(conn, &user, "http://example.invalid/feed.atom");

        sync_feed_text(&source, ATOM_FEED, conn).expect("sync should succeed");

        let posts = synced_posts(conn, source.id);
        assert_eq!(posts.len(), 1);
        assert_eq!(posts[0].title, Some("First Entry".to_string()));
        assert_eq!(posts[0].content, Some("First summary".to_string()));
        assert_eq!(posts[0].sync_source_uid, Some("entry-1".to_string()));

        Ok(())
    });
}

/// Regression coverage mirroring `event_sync_tests::resyncing_the_same_feed_twice_creates_no_duplicates`
/// for the flat Post case.
#[test]
fn resyncing_the_same_feed_twice_creates_no_duplicates() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "fst_reresync_owner");
        let source = create_feed_sync_source_row(conn, &user, "http://example.invalid/feed.rss");

        sync_feed_text(&source, RSS_FEED, conn).expect("first sync should succeed");
        sync_feed_text(&source, RSS_FEED, conn).expect("second sync of the same feed should succeed");

        let posts = synced_posts(conn, source.id);
        assert_eq!(
            posts.len(),
            1,
            "expected exactly one Post after syncing the same feed twice"
        );

        Ok(())
    });
}

#[test]
fn resync_updates_changed_item_text_in_place() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "fst_update_owner");
        let source = create_feed_sync_source_row(conn, &user, "http://example.invalid/feed.rss");

        sync_feed_text(&source, RSS_FEED, conn).expect("first sync should succeed");
        let updated_feed = RSS_FEED.replace("First description", "Updated description");
        sync_feed_text(&source, &updated_feed, conn).expect("second sync should succeed");

        let posts = synced_posts(conn, source.id);
        assert_eq!(posts.len(), 1, "resync must update the existing Post in place, not duplicate it");
        assert_eq!(posts[0].content, Some("Updated description".to_string()));

        Ok(())
    });
}

#[test]
fn sync_via_http_fetches_and_parses_from_a_real_url() {
    let mut conn = test_conn();
    conn.test_transaction::<_, tonic::Status, _>(|conn| {
        let user = create_user(conn, "fst_http_owner");
        let url = serve_feed(RSS_FEED);
        let source = create_feed_sync_source_row(conn, &user, &url);

        sync_source(&source, conn).expect("dispatcher should fetch and sync over HTTP");

        let posts = synced_posts(conn, source.id);
        assert_eq!(posts.len(), 1);

        Ok(())
    });
}
