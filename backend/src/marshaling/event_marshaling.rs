use std::collections::HashMap;
use std::mem::transmute;

use super::{
    load_media_lookup, MediaLookup, ToI32Moderation, ToProtoId, ToProtoMarshalablePost, ToProtoTime,
};
use crate::db_connection::PgPooledConnection;
use crate::protos::event_attendance::Attendee;
use crate::protos::*;
use crate::{marshaling::ToProtoAuthor, models};

use super::MarshalablePost;

pub type EventSyncSourceLookup = HashMap<i64, MarshalableEventSyncSource>;

pub fn load_event_sync_source_lookup(
    event_sync_source_ids: Vec<i64>,
    conn: &mut PgPooledConnection,
) -> Option<EventSyncSourceLookup> {
    Some(
        models::get_event_sync_sources_by_ids(event_sync_source_ids, conn)
            .into_iter()
            .map(|(source, owner)| (source.id, MarshalableEventSyncSource(source, owner)))
            .collect::<EventSyncSourceLookup>(),
    )
}

pub trait FindEventSyncSource {
    fn find_event_sync_source(&self, id: i64) -> Option<&MarshalableEventSyncSource>;
}

impl FindEventSyncSource for Option<&EventSyncSourceLookup> {
    fn find_event_sync_source(&self, id: i64) -> Option<&MarshalableEventSyncSource> {
        self.map(|lookup| lookup.get(&id)).flatten()
    }
}

#[derive(Debug, Clone)]
pub struct MarshalableEventSyncSource(pub models::EventSyncSource, pub models::Author);

pub trait ToProtoMarshalableEventSyncSource {
    fn to_proto(&self) -> EventSyncSource;
}

impl ToProtoMarshalableEventSyncSource for MarshalableEventSyncSource {
    fn to_proto(&self) -> EventSyncSource {
        let source = &self.0;
        let owner = &self.1;
        EventSyncSource {
            id: source.id.to_proto_id(),
            owner: Some(owner.to_proto(None)),
            sync_interval_seconds: source.sync_interval_seconds as u64,
            created_at: Some(source.created_at.to_proto()),
            updated_at: source.updated_at.map(|t| t.to_proto()),
            last_synced_at: source.last_synced_at.map(|t| t.to_proto()),
            event_count: source.event_count as u64,
            event_instance_count: source.event_instance_count as u64,
            configuration: configuration_to_proto(&source.configuration),
        }
    }
}

/// `configuration` JSONB shape today: `{"ics_subscription_url": "https://..."}` -- mirrors the
/// proto `oneof`, which currently has one variant.
pub fn configuration_to_proto(
    configuration: &serde_json::Value,
) -> Option<event_sync_source::Configuration> {
    configuration
        .get("ics_subscription_url")
        .and_then(|v| v.as_str())
        .map(|s| event_sync_source::Configuration::IcsSubscriptionUrl(s.to_string()))
}

pub fn configuration_to_json(
    configuration: &Option<event_sync_source::Configuration>,
) -> serde_json::Value {
    match configuration {
        Some(event_sync_source::Configuration::IcsSubscriptionUrl(url)) => {
            serde_json::json!({ "ics_subscription_url": url })
        }
        None => serde_json::json!({}),
    }
}

#[derive(Debug, Clone)]
pub struct MarshalableEvent(
    pub models::Event,
    pub MarshalablePost,
    pub Vec<MarshalableEventInstance>,
);
#[derive(Debug, Clone)]
pub struct MarshalableEventInstance(pub models::EventInstance, pub MarshalablePost);

pub fn convert_events(data: &Vec<MarshalableEvent>, conn: &mut PgPooledConnection) -> Vec<Event> {
    let media_ids: Vec<i64> = data
        .iter()
        .map(|ref marshalable_event| {
            let post = marshalable_event.1.to_owned();
            let mut ids = post.0.media.to_owned();
            post.1
                .as_ref()
                .map(|a| a.avatar_media_id.map(|id| ids.push(Some(id))));
            post.3
                .as_ref()
                .map(|a| a.avatar_media_id.map(|id| ids.push(Some(id))));
            post.4.iter().for_each(|reply| {
                ids.extend(reply.0.media.iter());
                reply
                    .1
                    .as_ref()
                    .map(|a| a.avatar_media_id.map(|id| ids.push(Some(id))));
            });
            ids
        })
        .flatten()
        .filter(|v| v.is_some())
        .map(|v| v.unwrap())
        .collect();

    let lookup = load_media_lookup(media_ids, conn);

    let event_sync_source_ids: Vec<i64> = data
        .iter()
        .filter_map(|marshalable_event| marshalable_event.0.event_sync_source_id)
        .collect();
    let sync_source_lookup = load_event_sync_source_lookup(event_sync_source_ids, conn);

    data.iter()
        .map(|marshalable_event| marshalable_event.to_proto(lookup.as_ref(), sync_source_lookup.as_ref()))
        .collect()
}
pub trait ToProtoMarshalableEvent {
    fn to_proto(
        &self,
        media_lookup: Option<&MediaLookup>,
        sync_source_lookup: Option<&EventSyncSourceLookup>,
    ) -> Event;
}

impl ToProtoMarshalableEvent for MarshalableEvent {
    fn to_proto(
        &self,
        media_lookup: Option<&MediaLookup>,
        sync_source_lookup: Option<&EventSyncSourceLookup>,
    ) -> Event {
        let event = self.0.to_owned();
        let post = self.1.to_owned();
        let instances = self.2.to_owned();
        let hide_location = event.info["hide_location_until_rsvp_approved"]
            .as_bool()
            .unwrap_or(false);
        log::info!(
            "ToProtoMarshalableEvent hide_location={} info={:?}",
            hide_location,
            event.info
        );
        // self.to_proto(username, None)
        Event {
            id: event.id.to_proto_id(),
            post: Some(post.to_proto(media_lookup)),
            instances: instances
                .iter()
                .map(|i| i.to_proto(media_lookup, hide_location))
                .collect(),
            info: serde_json::from_value(self.0.info.to_owned()).ok(),
            event_sync_source: event
                .event_sync_source_id
                .and_then(|id| sync_source_lookup.find_event_sync_source(id))
                .map(|source| source.to_proto()),
            ..Default::default()
        }
    }
}

pub trait ToProtoMarshalableEventInstance {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>, hide_location: bool) -> EventInstance;
}

impl ToProtoMarshalableEventInstance for MarshalableEventInstance {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>, hide_location: bool) -> EventInstance {
        let event_instance = self.0.to_owned();
        let marshalable_post = self.1.to_owned();
        let location: Option<Location> = if hide_location {
            None
        } else {
            event_instance.location.map(|c| c.to_proto_location())
        };
        EventInstance {
            id: event_instance.id.to_proto_id(),
            event_id: event_instance.event_id.to_proto_id(),
            post: Some(marshalable_post.to_proto(media_lookup)),
            starts_at: Some(event_instance.starts_at.to_proto()),
            ends_at: Some(event_instance.ends_at.to_proto()),
            info: Some(EventInstanceInfo {
                ..Default::default()
            }),
            location,
            event_sync_source_instance_id: event_instance.event_sync_source_instance_id,
            ..Default::default()
        }
    }
}

pub trait ToProtoLocation {
    fn to_proto_location(&self) -> Location;
}

impl ToProtoLocation for serde_json::Value {
    fn to_proto_location(&self) -> Location {
        serde_json::from_value(self.to_owned()).unwrap()
    }
}

pub trait ToProtoEventAttendance {
    fn to_proto(
        &self,
        include_auth_tokens: bool,
        include_private_note: bool,
        media_lookup: Option<&MediaLookup>,
    ) -> EventAttendance;
}

impl ToProtoEventAttendance for (models::EventAttendance, Option<models::Author>) {
    fn to_proto(
        &self,
        include_auth_tokens: bool,
        include_private_note: bool,
        media_lookup: Option<&MediaLookup>,
    ) -> EventAttendance {
        EventAttendance {
            id: self.0.id.to_proto_id(),
            event_instance_id: self.0.event_instance_id.to_proto_id(),
            attendee: match (&self.1, &self.0.anonymous_attendee) {
                (Some(author), _) => Some(Attendee::UserAttendee(
                    author.to_proto_user_attendee(media_lookup),
                )),
                (_, Some(anonymous_attendee)) => {
                    Some(Attendee::AnonymousAttendee(AnonymousAttendee {
                        name: anonymous_attendee
                            .get("name")
                            .unwrap()
                            .as_str()
                            .unwrap()
                            .to_string(),
                        //TODO add contact methods
                        contact_methods: vec![],
                        auth_token: if include_auth_tokens {
                            Some(
                                anonymous_attendee
                                    .get("auth_token")
                                    .unwrap()
                                    .as_str()
                                    .unwrap()
                                    .to_string(),
                            )
                        } else {
                            None
                        },
                    }))
                }
                _ => None,
            },
            number_of_guests: u32::try_from(self.0.number_of_guests).unwrap(),
            status: self.0.status.to_i32_attendance_status(),
            inviting_user_id: self.0.inviting_user_id.map(|id| id.to_proto_id()),
            public_note: self.0.public_note.clone(),
            private_note: if include_private_note {
                self.0.private_note.clone()
            } else {
                "".to_string()
            },
            moderation: self.0.moderation.to_i32_moderation(),
            created_at: Some(self.0.created_at.to_proto()),
            updated_at: self.0.updated_at.map(|t| t.to_proto()),
        }
    }
}

pub const ALL_ATTENDANCE_STATUSES: [AttendanceStatus; 4] = [
    AttendanceStatus::Interested,
    AttendanceStatus::Requested,
    AttendanceStatus::Going,
    AttendanceStatus::NotGoing,
    // AttendanceStatus::Went,
    // AttendanceStatus::DidNotGo,
];

pub trait ToProtoAttendanceStatus {
    fn to_proto_attendance_status(&self) -> Option<AttendanceStatus>;
}
impl ToProtoAttendanceStatus for String {
    fn to_proto_attendance_status(&self) -> Option<AttendanceStatus> {
        for attendance_status in ALL_ATTENDANCE_STATUSES {
            if attendance_status.as_str_name().eq_ignore_ascii_case(self) {
                return Some(attendance_status);
            }
        }
        return None;
    }
}
impl ToProtoAttendanceStatus for i32 {
    fn to_proto_attendance_status(&self) -> Option<AttendanceStatus> {
        Some(unsafe { transmute::<i32, AttendanceStatus>(*self) })
    }
}

pub trait ToStringAttendanceStatus {
    fn to_string_attendance_status(&self) -> String;
}
impl ToStringAttendanceStatus for AttendanceStatus {
    fn to_string_attendance_status(&self) -> String {
        self.as_str_name().to_string()
    }
}
impl ToStringAttendanceStatus for i32 {
    fn to_string_attendance_status(&self) -> String {
        self.to_proto_attendance_status()
            .unwrap()
            .to_string_attendance_status()
    }
}

pub trait ToI32AttendanceStatus {
    fn to_i32_attendance_status(&self) -> i32;
}
impl ToI32AttendanceStatus for String {
    fn to_i32_attendance_status(&self) -> i32 {
        self.to_proto_attendance_status()
            .unwrap()
            .to_i32_attendance_status()
    }
}
impl ToI32AttendanceStatus for AttendanceStatus {
    fn to_i32_attendance_status(&self) -> i32 {
        *self as i32
    }
}
