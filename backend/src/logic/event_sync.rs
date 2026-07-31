//! Pulls events from an `EventSyncSource`'s external calendar (currently only ICS subscription
//! URLs) and upserts them into `events`/`event_instances`/`posts`.
//!
//! Recurring `VEVENT`s (an `RRULE`) are expanded with the `rrule` crate: one ICS `UID` maps to
//! one `Event`, and each occurrence maps to one `EventInstance`, keyed by
//! `event_sync_source_instance_id = "{uid}|{occurrence_start_rfc3339}"` so re-syncing finds and
//! updates the same rows rather than duplicating them. A `VEVENT` with a `RECURRENCE-ID`
//! overrides that one occurrence's time/text (a moved or edited single instance of a series).
//!
//! Only occurrences ending within the last year through ~1 year out are created/updated.
//! Existing rows older than that are never touched, even if they'd otherwise be pruned for no
//! longer appearing in the feed.

use std::collections::{HashMap, HashSet};
use std::time::SystemTime;

use chrono::{DateTime, Duration, Utc};
use diesel::*;
use icalendar::{Calendar, CalendarDateTime, Component, DatePerhapsTime};
use rrule::{RRule, RRuleSet, Unvalidated};
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::{event_instances, event_sync_sources, events, posts};

const SYNC_PAST_WINDOW_DAYS: i64 = 365;
const SYNC_FUTURE_WINDOW_DAYS: i64 = 365;
const MAX_RRULE_OCCURRENCES: u16 = 2000;

/// Fetches `source`'s ICS URL over HTTP, then delegates to [`sync_event_sync_source_text`].
/// Split out so specs can exercise the parsing/upserting logic against a fixed ICS string
/// without any network access.
pub fn sync_event_sync_source(
    source: &models::EventSyncSource,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let url = ics_subscription_url(source)?;
    let ics_text = fetch_ics(url)?;
    sync_event_sync_source_text(source, &ics_text, conn)
}

/// RPC handlers here are plain sync functions, but in production they're still called from
/// within Rocket's (multi-threaded) Tokio runtime -- `reqwest::blocking` builds and tears down
/// its own nested runtime per call, which panics ("Cannot drop a runtime in a context where
/// blocking is not allowed") if done directly from an existing async context. `block_in_place`
/// tells Tokio this thread is about to block so it can hand off its other queued work first,
/// which is exactly what makes the nested runtime safe to create/drop -- but `block_in_place`
/// itself panics if there's no Tokio runtime at all (e.g. this same function called from a plain
/// `#[test]` or a `bin/`), so it's only used when actually inside one.
fn fetch_ics(url: &str) -> Result<String, Status> {
    let fetch = || {
        reqwest::blocking::get(url)
            .and_then(|response| response.error_for_status())
            .map_err(|e| {
                log::error!("Failed to fetch ICS from {}: {:?}", url, e);
                Status::new(Code::FailedPrecondition, "ics_fetch_failed")
            })?
            .text()
            .map_err(|e| {
                log::error!("Failed to read ICS response body from {}: {:?}", url, e);
                Status::new(Code::FailedPrecondition, "ics_fetch_failed")
            })
    };

    if tokio::runtime::Handle::try_current().is_ok() {
        tokio::task::block_in_place(fetch)
    } else {
        fetch()
    }
}

fn ics_subscription_url(source: &models::EventSyncSource) -> Result<&str, Status> {
    source
        .configuration
        .get("ics_subscription_url")
        .and_then(|v| v.as_str())
        .filter(|s| !s.trim().is_empty())
        .ok_or_else(|| Status::new(Code::FailedPrecondition, "ics_url_required"))
}

struct Occurrence {
    instance_id: String,
    starts_at: DateTime<Utc>,
    ends_at: DateTime<Utc>,
    location: Option<String>,
    title: Option<String>,
    content: Option<String>,
    /// Whether this occurrence came from its own `RECURRENCE-ID` VEVENT (as opposed to being a
    /// plain expansion of the master's `RRULE`) -- only overrides get their own instance `Post`
    /// text; plain expansions leave their instance `Post` empty, same as normal (non-synced)
    /// recurring events do.
    is_override: bool,
}

struct EventGroup {
    uid: String,
    title: Option<String>,
    content: Option<String>,
    link: Option<String>,
    occurrences: Vec<Occurrence>,
}

pub fn sync_event_sync_source_text(
    source: &models::EventSyncSource,
    ics_text: &str,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let calendar: Calendar = ics_text.parse().map_err(|e| {
        log::error!("Failed to parse ICS text: {:?}", e);
        Status::new(Code::FailedPrecondition, "ics_parse_failed")
    })?;

    let now = Utc::now();
    let window_start = now - Duration::days(SYNC_PAST_WINDOW_DAYS);
    let window_end = now + Duration::days(SYNC_FUTURE_WINDOW_DAYS);

    let event_groups = group_vevents(&calendar, window_start, window_end);

    let owner_user_id = source.user_id;
    let moderation = default_event_moderation(conn);

    let window_start_db: SystemTime = window_start.into();

    let result = conn.transaction::<(), diesel::result::Error, _>(|conn| {
        let existing_events: Vec<models::Event> = events::table
            .filter(events::event_sync_source_id.eq(source.id))
            .load::<models::Event>(conn)?;
        let mut existing_by_uid: HashMap<String, models::Event> = existing_events
            .into_iter()
            .filter_map(|e| {
                let uid = e
                    .info
                    .get("event_sync_source_uid")
                    .and_then(|v| v.as_str())
                    .map(str::to_string)?;
                Some((uid, e))
            })
            .collect();

        for group in &event_groups {
            let db_event = match existing_by_uid.remove(&group.uid) {
                Some(existing) => {
                    sync_post_text(conn, existing.post_id, &group.title, &group.content, &group.link)?;
                    existing
                }
                None => create_event_for_group(conn, source.id, owner_user_id, &moderation, group)?,
            };

            reconcile_instances(conn, db_event.id, owner_user_id, &moderation, group, window_start_db)?;
        }

        // Events whose UID no longer appears in the feed at all: prune their in-window
        // instances the same way `reconcile_instances` does for a group with zero occurrences,
        // then delete the event itself (cascades its instances/attendances) if nothing's left.
        for (_, stale_event) in existing_by_uid {
            let empty_group = EventGroup {
                uid: String::new(),
                title: None,
                content: None,
                link: None,
                occurrences: vec![],
            };
            reconcile_instances(
                conn,
                stale_event.id,
                owner_user_id,
                &moderation,
                &empty_group,
                window_start_db,
            )?;

            let remaining: i64 = event_instances::table
                .filter(event_instances::event_id.eq(stale_event.id))
                .count()
                .get_result(conn)?;
            if remaining == 0 {
                diesel::delete(events::table.filter(events::id.eq(stale_event.id))).execute(conn)?;
            }
        }

        let event_count: i64 = events::table
            .filter(events::event_sync_source_id.eq(source.id))
            .count()
            .get_result(conn)?;
        let event_instance_count: i64 = event_instances::table
            .inner_join(events::table)
            .filter(events::event_sync_source_id.eq(source.id))
            .count()
            .get_result(conn)?;

        diesel::update(event_sync_sources::table.filter(event_sync_sources::id.eq(source.id)))
            .set((
                event_sync_sources::last_synced_at.eq(SystemTime::now()),
                event_sync_sources::event_count.eq(event_count),
                event_sync_sources::event_instance_count.eq(event_instance_count),
            ))
            .execute(conn)?;

        crate::logic::update_event_counts(owner_user_id, conn)?;

        Ok(())
    });

    result.map_err(|e| {
        log::error!("Failed to sync EventSyncSource {}: {:?}", source.id, e);
        Status::new(Code::Internal, "failed_to_sync_event_sync_source")
    })
}

fn default_event_moderation(conn: &mut PgPooledConnection) -> String {
    crate::rpcs::get_server_configuration_proto(conn)
        .map(|c| match c.event_settings.unwrap_or_default().default_moderation() {
            Moderation::Pending => Moderation::Pending.as_str_name(),
            _ => Moderation::Unmoderated.as_str_name(),
        })
        .unwrap_or_else(|_| Moderation::Unmoderated.as_str_name())
        .to_string()
}

fn create_event_for_group(
    conn: &mut PgPooledConnection,
    source_id: i64,
    owner_user_id: i64,
    moderation: &str,
    group: &EventGroup,
) -> Result<models::Event, diesel::result::Error> {
    let post = insert_into(posts::table)
        .values(&models::NewPost {
            user_id: Some(owner_user_id),
            parent_post_id: None,
            title: group.title.clone(),
            link: group.link.clone(),
            content: group.content.clone(),
            visibility: Visibility::GlobalPublic.to_string_visibility(),
            embed_link: false,
            context: PostContext::Event.to_string_post_context(),
            moderation: moderation.to_string(),
            media: vec![],
        })
        .returning(models::POST_COLUMNS)
        .get_result::<models::Post>(conn)?;

    insert_into(events::table)
        .values(&models::NewEvent {
            post_id: post.id,
            info: json!({ "event_sync_source_uid": group.uid }),
            event_sync_source_id: Some(source_id),
        })
        .get_result::<models::Event>(conn)
}

fn sync_post_text(
    conn: &mut PgPooledConnection,
    post_id: i64,
    title: &Option<String>,
    content: &Option<String>,
    link: &Option<String>,
) -> Result<(), diesel::result::Error> {
    let post: models::Post = posts::table
        .select(models::POST_COLUMNS)
        .filter(posts::id.eq(post_id))
        .first(conn)?;
    if &post.title != title || &post.content != content || &post.link != link {
        diesel::update(posts::table.filter(posts::id.eq(post_id)))
            .set((
                posts::title.eq(title),
                posts::content.eq(content),
                posts::link.eq(link),
            ))
            .execute(conn)?;
    }
    Ok(())
}

fn location_json(location: &Option<String>) -> Option<serde_json::Value> {
    location.as_ref().map(|address| {
        serde_json::to_value(Location {
            id: String::new(),
            creator_id: String::new(),
            uniformly_formatted_address: address.clone(),
        })
        .unwrap()
    })
}

/// Creates/updates `EventInstance`s (+ their `Post`s) for `group`'s occurrences under
/// `event_id`, then deletes any existing instance under `event_id` that's no longer present in
/// `group.occurrences` -- but only if that instance's `ends_at` is still within the sync window
/// (`>= window_start_db`); older ones are left untouched no matter what the feed says now.
fn reconcile_instances(
    conn: &mut PgPooledConnection,
    event_id: i64,
    owner_user_id: i64,
    moderation: &str,
    group: &EventGroup,
    window_start_db: SystemTime,
) -> Result<(), diesel::result::Error> {
    let existing_instances: Vec<models::EventInstance> = event_instances::table
        .select(models::EVENT_INSTANCE_COLUMNS)
        .filter(event_instances::event_id.eq(event_id))
        .load::<models::EventInstance>(conn)?;
    let mut existing_by_instance_id: HashMap<String, models::EventInstance> = existing_instances
        .into_iter()
        .filter_map(|i| {
            i.event_sync_source_instance_id
                .clone()
                .map(|id| (id, i))
        })
        .collect();

    for occ in &group.occurrences {
        let starts_at_db: SystemTime = occ.starts_at.into();
        let ends_at_db: SystemTime = occ.ends_at.into();
        let loc_json = location_json(&occ.location);

        match existing_by_instance_id.remove(&occ.instance_id) {
            Some(existing_instance) => {
                if existing_instance.starts_at != starts_at_db
                    || existing_instance.ends_at != ends_at_db
                    || existing_instance.location != loc_json
                {
                    diesel::update(event_instances::table.filter(event_instances::id.eq(existing_instance.id)))
                        .set((
                            event_instances::starts_at.eq(starts_at_db),
                            event_instances::ends_at.eq(ends_at_db),
                            event_instances::location.eq(&loc_json),
                        ))
                        .execute(conn)?;
                }
                if occ.is_override {
                    sync_post_text(conn, existing_instance.post_id, &occ.title, &occ.content, &None)?;
                }
            }
            None => {
                let instance_post = insert_into(posts::table)
                    .values(&models::NewPost {
                        user_id: Some(owner_user_id),
                        parent_post_id: None,
                        title: if occ.is_override { occ.title.clone() } else { None },
                        link: None,
                        content: if occ.is_override { occ.content.clone() } else { None },
                        visibility: Visibility::GlobalPublic.to_string_visibility(),
                        embed_link: false,
                        context: PostContext::EventInstance.as_str_name().to_string(),
                        moderation: moderation.to_string(),
                        media: vec![],
                    })
                    .returning(models::POST_COLUMNS)
                    .get_result::<models::Post>(conn)?;
                insert_into(event_instances::table)
                    .values(&models::NewEventInstance {
                        event_id,
                        post_id: instance_post.id,
                        info: json!({}),
                        starts_at: starts_at_db,
                        ends_at: ends_at_db,
                        location: loc_json,
                        event_sync_source_instance_id: Some(occ.instance_id.clone()),
                    })
                    .execute(conn)?;
            }
        }
    }

    let stale_instance_ids: Vec<i64> = existing_by_instance_id
        .values()
        .filter(|i| i.ends_at >= window_start_db)
        .map(|i| i.id)
        .collect();
    if !stale_instance_ids.is_empty() {
        diesel::delete(event_instances::table.filter(event_instances::id.eq_any(stale_instance_ids)))
            .execute(conn)?;
    }

    Ok(())
}

/// Converts an `icalendar` `DATE`/`DATE-TIME` into a concrete UTC instant. Floating (no
/// timezone) times are treated as already-UTC -- a pragmatic fallback rather than an accurate
/// one, since there's no user-local timezone to resolve them against server-side.
fn date_perhaps_time_to_utc(d: &DatePerhapsTime) -> Option<DateTime<Utc>> {
    match d {
        DatePerhapsTime::Date(date) => date
            .and_hms_opt(0, 0, 0)
            .map(|ndt| DateTime::<Utc>::from_naive_utc_and_offset(ndt, Utc)),
        DatePerhapsTime::DateTime(CalendarDateTime::Utc(dt)) => Some(*dt),
        DatePerhapsTime::DateTime(CalendarDateTime::Floating(ndt)) => {
            Some(DateTime::<Utc>::from_naive_utc_and_offset(*ndt, Utc))
        }
        DatePerhapsTime::DateTime(with_tz @ CalendarDateTime::WithTimezone { date_time, .. }) => {
            with_tz.try_into_utc().or_else(|| {
                Some(DateTime::<Utc>::from_naive_utc_and_offset(*date_time, Utc))
            })
        }
    }
}

fn get_date_property(event: &icalendar::Event, key: &str) -> Option<DateTime<Utc>> {
    let property = event.properties().get(key)?;
    let dpt = DatePerhapsTime::from_property(property)?;
    date_perhaps_time_to_utc(&dpt)
}

/// `EXDATE` may list multiple comma-separated date-times in one property (RFC 5545 §3.8.5.1).
/// Repeated `EXDATE:` lines aren't handled -- an accepted simplification given how rare they are
/// in practice compared to the single-line-with-commas form real calendar exporters use.
fn parse_exdates(event: &icalendar::Event) -> Vec<DateTime<Utc>> {
    let Some(raw) = event.property_value("EXDATE") else {
        return vec![];
    };
    raw.split(',')
        .filter_map(|token| token.trim().parse::<CalendarDateTime>().ok())
        .filter_map(|cdt| date_perhaps_time_to_utc(&DatePerhapsTime::DateTime(cdt)))
        .collect()
}

fn group_vevents(
    calendar: &Calendar,
    window_start: DateTime<Utc>,
    window_end: DateTime<Utc>,
) -> Vec<EventGroup> {
    let mut by_uid: HashMap<String, Vec<&icalendar::Event>> = HashMap::new();
    for component in calendar.iter() {
        if let Some(event) = component.as_event() {
            if let Some(uid) = event.property_value("UID") {
                by_uid.entry(uid.to_string()).or_default().push(event);
            }
        }
    }

    let mut groups = vec![];
    for (uid, vevents) in by_uid {
        let Some(master) = vevents
            .iter()
            .find(|e| e.property_value("RECURRENCE-ID").is_none())
            .copied()
        else {
            continue; // only override(s) present, nothing to anchor the series to
        };
        let Some(master_start) = get_date_property(master, "DTSTART") else {
            continue; // no DTSTART, nothing we can do with this VEVENT
        };
        let master_end = get_date_property(master, "DTEND").unwrap_or(master_start);
        let duration = master_end - master_start;

        let overrides: HashMap<DateTime<Utc>, &icalendar::Event> = vevents
            .iter()
            .filter(|e| e.property_value("RECURRENCE-ID").is_some())
            .filter_map(|e| get_date_property(e, "RECURRENCE-ID").map(|dt| (dt, *e)))
            .collect();

        let occurrence_starts = expand_occurrence_starts(master, master_start, window_start, window_end);

        let mut occurrences = vec![];
        let mut seen_starts: HashSet<DateTime<Utc>> = HashSet::new();
        for occ_start in occurrence_starts {
            seen_starts.insert(occ_start);
            let occ_end = occ_start + duration;
            if occ_end < window_start {
                continue;
            }
            let override_event = overrides.get(&occ_start).copied();
            occurrences.push(build_occurrence(&uid, occ_start, occ_end, master, override_event, duration));
        }

        // Override VEVENTs whose RECURRENCE-ID falls outside the plain RRULE expansion (e.g. an
        // occurrence moved to a different time) still need their own instance.
        for (recurrence_id, override_event) in &overrides {
            if seen_starts.contains(recurrence_id) {
                continue;
            }
            let starts_at = get_date_property(override_event, "DTSTART").unwrap_or(*recurrence_id);
            let ends_at = get_date_property(override_event, "DTEND").unwrap_or(starts_at + duration);
            if ends_at < window_start {
                continue;
            }
            occurrences.push(build_occurrence(&uid, *recurrence_id, ends_at, master, Some(override_event), duration).with_start(starts_at));
        }

        if occurrences.is_empty() {
            continue;
        }

        groups.push(EventGroup {
            uid,
            title: master.property_value("SUMMARY").map(str::to_string),
            content: master.property_value("DESCRIPTION").map(str::to_string),
            link: master.property_value("URL").map(str::to_string),
            occurrences,
        });
    }
    groups
}

fn build_occurrence(
    uid: &str,
    instance_key: DateTime<Utc>,
    ends_at: DateTime<Utc>,
    master: &icalendar::Event,
    override_event: Option<&icalendar::Event>,
    _duration: Duration,
) -> Occurrence {
    let source_event = override_event.unwrap_or(master);
    Occurrence {
        instance_id: format!("{}|{}", uid, instance_key.to_rfc3339()),
        starts_at: instance_key,
        ends_at,
        location: source_event.property_value("LOCATION").map(str::to_string),
        title: override_event.and_then(|e| e.property_value("SUMMARY")).map(str::to_string),
        content: override_event.and_then(|e| e.property_value("DESCRIPTION")).map(str::to_string),
        is_override: override_event.is_some(),
    }
}

impl Occurrence {
    fn with_start(mut self, starts_at: DateTime<Utc>) -> Self {
        self.starts_at = starts_at;
        self
    }
}

fn expand_occurrence_starts(
    master: &icalendar::Event,
    master_start: DateTime<Utc>,
    window_start: DateTime<Utc>,
    window_end: DateTime<Utc>,
) -> Vec<DateTime<Utc>> {
    let Some(rrule_str) = master.property_value("RRULE") else {
        return vec![master_start];
    };

    let dt_start_rrule = master_start.with_timezone(&rrule::Tz::UTC);
    let parsed = rrule_str
        .parse::<RRule<Unvalidated>>()
        .map_err(|e| e.to_string())
        .and_then(|r| r.validate(dt_start_rrule).map_err(|e| e.to_string()));

    let validated_rrule = match parsed {
        Ok(r) => r,
        Err(e) => {
            log::warn!("Failed to parse/validate RRULE '{}': {}", rrule_str, e);
            return vec![master_start];
        }
    };

    let mut set = RRuleSet::new(dt_start_rrule).rrule(validated_rrule);
    for exdate in parse_exdates(master) {
        set = set.exdate(exdate.with_timezone(&rrule::Tz::UTC));
    }

    let result = set
        .after(window_start.with_timezone(&rrule::Tz::UTC))
        .before(window_end.with_timezone(&rrule::Tz::UTC))
        .all(MAX_RRULE_OCCURRENCES);

    result.dates.iter().map(|d| d.with_timezone(&Utc)).collect()
}
