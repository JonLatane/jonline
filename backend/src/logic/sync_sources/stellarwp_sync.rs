//! Syncs Events/Occasions from a site running [The Events Calendar](https://theeventscalendar.com/)
//! (a StellarWP WordPress plugin), following the plugin's `paged=N` pagination.
//!
//! The plugin's iCal export (`?post_type=tribe_events&ical=1&eventDisplay=list`) returns at most
//! its "events per page" setting's worth of events (30 on many sites) -- a plain
//! `ics_subscription_url` source on a busy calendar therefore only ever sees the next couple of
//! weeks. The same URL with `&paged=2`, `&paged=3`, ... returns the following pages (neighboring
//! pages can overlap by a day, so events are de-duplicated), and a page past the end is an
//! HTTP 200 with an *empty* body. [`collect_pages`] fetches pages until one of those, merges them
//! into one [`Calendar`], and hands it to `event_sync::sync_source_calendar` -- everything after
//! the fetch (recurrence expansion, upserting, missing-grace-period pruning) is shared with plain
//! ICS sources.
//!
//! A feed that's still returning new events at [`MAX_PAGES`] is treated as *truncated*: the merged
//! calendar's `coverage_horizon` (the latest start seen) is passed along so occasions beyond it
//! aren't mistaken for deleted ones. Any failed page fails the whole sync -- a partially fetched
//! feed is never reconciled as though it were complete.
//!
//! Creating/updating a source (an RPC, so a human is waiting) syncs only the first page inline
//! ([`sync_source_stellarwp_first_page`]); `logic::sync_source_after_edit` finishes the rest on a
//! background thread.

use std::collections::HashSet;
use std::time::Duration;

use chrono::{DateTime, Utc};
use icalendar::{Calendar, Component};
use reqwest::Url;
use tonic::{Code, Status};

use super::event_sync::{get_date_property, parse_calendar, sync_source_calendar};
use crate::db_connection::PgPooledConnection;
use crate::models;

/// The most pages one sync fetches. A page is ~30 events, so this bounds a sync at ~1,200 events;
/// real calendars seen so far run out at 25-35 pages (a year or so ahead).
pub const MAX_PAGES: u32 = 40;
/// Pages fetched concurrently. Small, so a sync stays polite to a (usually small, shared-hosting)
/// WordPress site while still finishing in a fraction of the time a purely sequential fetch takes
/// (pages can take several seconds each).
const PAGES_PER_BATCH: u32 = 4;
const REQUEST_TIMEOUT: Duration = Duration::from_secs(60);
const USER_AGENT: &str = "Rellm-SyncSource/1.0 (+https://rellm.org)";

/// Syncs every page of `source`'s StellarWP endpoint (up to [`MAX_PAGES`]).
pub fn sync_source_stellarwp(
    source: &models::SyncSource,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    sync_pages(source, MAX_PAGES, conn)
}

/// Syncs only the first page of `source`'s StellarWP endpoint -- what a create/update RPC does
/// inline before handing the remaining pages to a background sync. Occasions past the first page's
/// coverage are left alone rather than treated as missing.
pub fn sync_source_stellarwp_first_page(
    source: &models::SyncSource,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    sync_pages(source, 1, conn)
}

fn sync_pages(
    source: &models::SyncSource,
    max_pages: u32,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let endpoint = stellarwp_subscription_endpoint(source)?;
    crate::init_crypto();
    let paged = in_blocking_context(|| {
        let client = reqwest::blocking::Client::builder()
            .user_agent(USER_AGENT)
            .timeout(REQUEST_TIMEOUT)
            .build()
            .map_err(|e| {
                log::error!("Failed to build HTTP client for StellarWP sync: {:?}", e);
                Status::new(Code::Internal, "stellarwp_fetch_failed")
            })?;
        collect_pages(max_pages, |page| {
            fetch_page(&client, &stellarwp_page_url(endpoint, page)?)
        })
    })?;
    sync_source_calendar(source, &paged.calendar, paged.coverage_horizon, conn)
}

fn stellarwp_subscription_endpoint(source: &models::SyncSource) -> Result<&str, Status> {
    source
        .configuration
        .get("stellarwp_subscription_endpoint")
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty())
        .ok_or_else(|| Status::new(Code::FailedPrecondition, "stellarwp_endpoint_required"))
}

/// `endpoint` with its `paged` query parameter set to `page` (replacing any `paged` it already
/// carried). Page 1 omits `paged` entirely: WordPress redirects `?paged=1` to the canonical URL.
/// Also what create/update use to validate a new endpoint.
pub fn stellarwp_page_url(endpoint: &str, page: u32) -> Result<Url, Status> {
    let mut url = Url::parse(endpoint.trim()).map_err(|_| invalid_endpoint())?;
    if !matches!(url.scheme(), "http" | "https") || url.host_str().is_none() {
        return Err(invalid_endpoint());
    }
    let kept: Vec<(String, String)> = url
        .query_pairs()
        .filter(|(key, _)| key != "paged")
        .map(|(key, value)| (key.into_owned(), value.into_owned()))
        .collect();
    {
        let mut pairs = url.query_pairs_mut();
        pairs.clear().extend_pairs(&kept);
        if page > 1 {
            pairs.append_pair("paged", &page.to_string());
        }
    }
    Ok(url)
}

fn invalid_endpoint() -> Status {
    Status::new(Code::InvalidArgument, "stellarwp_subscription_endpoint_invalid")
}

/// Same reasoning as `event_sync::fetch_ics`: handlers are plain sync functions but still run
/// inside Rocket's Tokio runtime in production, and `reqwest::blocking` panics if it builds or
/// drops its nested runtime directly in an async context.
fn in_blocking_context<T>(f: impl FnOnce() -> T) -> T {
    if tokio::runtime::Handle::try_current().is_ok() {
        tokio::task::block_in_place(f)
    } else {
        f()
    }
}

/// One page's body, retried once on a transient failure.
fn fetch_page(client: &reqwest::blocking::Client, url: &Url) -> Result<String, Status> {
    let mut last_error = None;
    for _attempt in 0..2 {
        match client
            .get(url.clone())
            .send()
            .and_then(|response| response.error_for_status())
            .and_then(|response| response.text())
        {
            Ok(text) => return Ok(text),
            Err(e) => {
                log::warn!("Failed to fetch StellarWP page {}: {:?}", url, e);
                last_error = Some(e);
            }
        }
    }
    log::error!(
        "Giving up fetching StellarWP page {}: {:?}",
        url,
        last_error
    );
    Err(Status::new(Code::FailedPrecondition, "stellarwp_fetch_failed"))
}

#[derive(Debug)]
pub struct PagedCalendar {
    /// Every distinct VEVENT across the fetched pages.
    pub calendar: Calendar,
    /// `Some(latest event start seen)` if the fetch stopped before reaching the end of the feed
    /// (hit `max_pages` with the feed still returning new events); `None` if it reached the end.
    pub coverage_horizon: Option<DateTime<Utc>>,
}

/// What one fetched page turned out to be.
enum Page {
    /// Past the end of the feed: an empty body.
    End,
    Calendar(Calendar),
}

/// Fetches pages `1..=max_pages` with `fetch_page` (called with the 1-based page number, possibly
/// from several threads at once), merging their VEVENTs and stopping at the first page that's past
/// the end of the feed (an empty body, for pages after the first) or adds nothing new -- the
/// latter guards against a site that ignores `paged` and serves the same page forever.
pub fn collect_pages<F>(max_pages: u32, fetch_page: F) -> Result<PagedCalendar, Status>
where
    F: Fn(u32) -> Result<String, Status> + Sync,
{
    let mut merged = Calendar::new();
    let mut seen_keys: HashSet<String> = HashSet::new();
    let mut latest_start: Option<DateTime<Utc>> = None;
    let mut reached_end = false;

    let mut batch_start = 1;
    'batches: while batch_start <= max_pages {
        let batch: Vec<u32> = (batch_start..=max_pages.min(batch_start + PAGES_PER_BATCH - 1)).collect();
        batch_start += PAGES_PER_BATCH;

        // Fetched concurrently but examined strictly in order, so a failure in a page past the
        // end of the feed (a speculative overshoot of the batch) is never even looked at.
        let bodies: Vec<Result<String, Status>> = if batch.len() == 1 {
            vec![fetch_page(batch[0])]
        } else {
            std::thread::scope(|scope| {
                let handles: Vec<_> = batch
                    .iter()
                    .map(|&page| {
                        let fetch_page = &fetch_page;
                        scope.spawn(move || fetch_page(page))
                    })
                    .collect();
                handles
                    .into_iter()
                    .map(|handle| {
                        handle.join().unwrap_or_else(|_| {
                            Err(Status::new(Code::Internal, "stellarwp_fetch_failed"))
                        })
                    })
                    .collect()
            })
        };

        for (&page_number, body) in batch.iter().zip(bodies) {
            let calendar = match classify_page(page_number, &body?)? {
                Page::End => {
                    reached_end = true;
                    break 'batches;
                }
                Page::Calendar(calendar) => calendar,
            };

            let mut new_events = 0;
            for component in calendar.iter() {
                let Some(event) = component.as_event() else {
                    continue;
                };
                if !seen_keys.insert(event_key(event)) {
                    continue;
                }
                new_events += 1;
                if let Some(start) = get_date_property(event, "DTSTART") {
                    latest_start = Some(latest_start.map_or(start, |latest| latest.max(start)));
                }
                merged.push(event.clone());
            }
            if new_events == 0 {
                reached_end = true;
                break 'batches;
            }
        }
    }

    Ok(PagedCalendar {
        calendar: merged,
        coverage_horizon: if reached_end {
            None
        } else {
            Some(latest_start.unwrap_or_else(Utc::now))
        },
    })
}

/// An empty body means "past the end" for any page after the first. Anything else must parse as a
/// calendar -- in particular a non-empty non-calendar body (a Cloudflare challenge page, say) is an
/// error rather than a silent end of the feed, which would make everything beyond it look deleted.
fn classify_page(page_number: u32, body: &str) -> Result<Page, Status> {
    if body.trim().is_empty() {
        return if page_number > 1 {
            Ok(Page::End)
        } else {
            Err(Status::new(Code::FailedPrecondition, "stellarwp_empty_response"))
        };
    }
    parse_calendar(body).map(Page::Calendar)
}

/// Identifies one VEVENT across overlapping pages: for a recurring series every occurrence shares
/// a `UID`, and each is told apart by `RECURRENCE-ID`/`DTSTART`.
fn event_key(event: &icalendar::Event) -> String {
    format!(
        "{}\u{1f}{}\u{1f}{}",
        event.property_value("UID").unwrap_or(""),
        event.property_value("RECURRENCE-ID").unwrap_or(""),
        event.property_value("DTSTART").unwrap_or(""),
    )
}
