// use std::mem::transmute;

// use diesel::*;
// use tonic::Code;
// use tonic::Status;

use super::id_marshaling::ToProtoId;
// use super::ToProtoPost;

use super::MediaLookup;
use super::ToProtoTime;
use crate::ToProtoMarshalablePost;
use crate::models;
use crate::protos::*;

use super::MarshalablePost;

pub struct MarshalableEvent(
    pub models::Event,
    pub MarshalablePost,
    pub Vec<MarshalableEventInstance>,
);
pub struct MarshalableEventInstance(pub models::EventInstance, pub Option<MarshalablePost>);

pub trait ToProtoMarshalableEvent {
    fn to_proto(
        &self,
        media_lookup: Option<&MediaLookup>,
    ) -> Event;
}

impl ToProtoMarshalableEvent for MarshalableEvent {
    fn to_proto(
        &self,
        media_lookup: Option<&MediaLookup>,
    ) -> Event {
        let event = self.0;
        let post = self.1;
        let instances = self.2;
        // self.to_proto(username, None)
        Event {
            id: event.id.to_proto_id(),
            post: Some(post.to_proto(media_lookup)),
            instances: instances
                .iter()
                .map(|i| i.to_proto(media_lookup))
                .collect(),
            info: Some(EventInfo {
                // start_time: self.start_time.map(|t| t.to_proto()),
                // end_time: self.end_time.map(|t| t.to_proto()),
                // location: self.location.to_owned(),
                ..Default::default()
            }),
            ..Default::default()
        }
    }
}

pub trait ToProtoMarshalableEventInstance {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> EventInstance;
}

impl ToProtoMarshalableEventInstance for MarshalableEventInstance {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> EventInstance {
        let event_instance = self.0;
        let marshalable_post = self.1;
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
