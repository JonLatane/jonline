use std::mem::transmute;

use super::{
    load_media_lookup, MediaLookup, ToI32Moderation, ToProtoId, ToProtoMarshalablePost, ToProtoTime,
};
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::event_attendance::Attendee;
use crate::protos::*;

use super::MarshalablePost;

#[derive(Debug, Clone)]
pub struct MarshalableEvent(
    pub models::Event,
    pub MarshalablePost,
    pub Vec<MarshalableEventInstance>,
);
#[derive(Debug, Clone)]
pub struct MarshalableEventInstance(pub models::EventInstance, pub Option<MarshalablePost>);

pub fn convert_events(data: &Vec<MarshalableEvent>, conn: &mut PgPooledConnection) -> Vec<Event> {
    let media_ids: Vec<i64> = data
        .iter()
        .map(|ref marshalable_event| {
            let post = marshalable_event.1.to_owned();
            let mut ids = post.0.media.to_owned();
            post.1
                .as_ref()
                .map(|a| a.avatar_media_id.map(|id| ids.push(id)));
            post.3.iter().for_each(|reply| {
                ids.extend(reply.0.media.iter());
                reply
                    .1
                    .as_ref()
                    .map(|a| a.avatar_media_id.map(|id| ids.push(id)));
            });
            ids
        })
        .flatten()
        .collect();

    let lookup = load_media_lookup(media_ids, conn);

    data.iter()
        .map(|marshalable_event| marshalable_event.to_proto(lookup.as_ref()))
        .collect()
}
pub trait ToProtoMarshalableEvent {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> Event;
}

impl ToProtoMarshalableEvent for MarshalableEvent {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> Event {
        let event = self.0.to_owned();
        let post = self.1.to_owned();
        let instances = self.2.to_owned();
        // self.to_proto(username, None)
        Event {
            id: event.id.to_proto_id(),
            post: Some(post.to_proto(media_lookup)),
            instances: instances.iter().map(|i| i.to_proto(media_lookup)).collect(),
            info: serde_json::from_value(self.0.info.to_owned()).ok(),
            ..Default::default()
        }
    }
}

pub trait ToProtoMarshalableEventInstance {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> EventInstance;
}

impl ToProtoMarshalableEventInstance for MarshalableEventInstance {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> EventInstance {
        let event_instance = self.0.to_owned();
        let marshalable_post = self.1.to_owned();
        let location: Option<Location> = event_instance
            .location
            .to_owned()
            .map(|c| serde_json::from_value(c).unwrap());
        EventInstance {
            id: event_instance.id.to_proto_id(),
            event_id: event_instance.event_id.to_proto_id(),
            post: marshalable_post.map(|p| p.to_proto(media_lookup)),
            starts_at: Some(event_instance.starts_at.to_proto()),
            ends_at: Some(event_instance.ends_at.to_proto()),
            info: Some(EventInstanceInfo {
                ..Default::default()
            }),
            location,
            ..Default::default()
        }
    }
}

pub trait ToProtoEventAttendance {
    fn to_proto(&self, include_auth_tokens: bool, include_private_note: bool) -> EventAttendance;
}

impl ToProtoEventAttendance for models::EventAttendance {
    fn to_proto(&self, include_auth_tokens: bool, include_private_note: bool) -> EventAttendance {
        EventAttendance {
            // id: self.id.to_proto_id(),
            event_instance_id: self.event_instance_id.to_proto_id(),
            attendee: match (self.user_id, &self.anonymous_attendee) {
                (Some(user_id), _) => Some(Attendee::UserId(user_id.to_proto_id())),
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
            number_of_guests: u32::try_from(self.number_of_guests).unwrap(),
            status: self.status.to_i32_attendance_status(),
            inviting_user_id: self.inviting_user_id.map(|id| id.to_proto_id()),
            public_note: self.public_note.clone(),
            private_note: if include_private_note {
                self.private_note.clone()
            } else {
                "".to_string()
            },
            moderation: self.moderation.to_i32_moderation(),
            created_at: Some(self.created_at.to_proto()),
            updated_at: self.updated_at.map(|t| t.to_proto()),
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
