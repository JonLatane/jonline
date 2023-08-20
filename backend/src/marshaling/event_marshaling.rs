// use std::mem::transmute;

// use diesel::*;
// use tonic::Code;
// use tonic::Status;

use super::id_marshaling::ToProtoId;
use super::ToProtoPost;

use super::MediaLookup;
use super::ToProtoTime;
use crate::models;
use crate::protos::*;

use super::MarshalablePost;

pub struct MarshalableEvent(
    pub models::Event,
    pub MarshalablePost,
    pub Vec<MarshalableEventInstance>,
);
pub struct MarshalableEventInstance(pub models::EventInstance, pub Option<MarshalablePost>);

pub trait ToProtoEvent {
    fn to_proto(
        &self,
        post: &models::Post,
        author: Option<&models::Author>,
        media_lookup: Option<&MediaLookup>,
        instances: &Vec<(
            &models::EventInstance,
            Option<&models::Post>,
            Option<&models::Author>,
        )>,
    ) -> Event;
}

impl ToProtoEvent for models::Event {
    fn to_proto(
        &self,
        post: &models::Post,
        author: Option<&models::Author>,
        media_lookup: Option<&MediaLookup>,
        instances: &Vec<(
            &models::EventInstance,
            Option<&models::Post>,
            Option<&models::Author>,
        )>,
    ) -> Event {
        // self.to_proto(username, None)
        Event {
            id: self.id.to_proto_id(),
            post: Some(post.to_proto(author, None, media_lookup)),
            instances: instances
                .iter()
                .map(|(i, p, a)| i.to_proto(p, a, media_lookup))
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

pub trait ToProtoEventInstance {
    fn to_proto(
        &self,
        post: &Option<&models::Post>,
        author: &Option<&models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> EventInstance;
}

impl ToProtoEventInstance for models::EventInstance {
    fn to_proto(
        &self,
        post: &Option<&models::Post>,
        author: &Option<&models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> EventInstance {
        let location: Option<Location> = self
            .location
            .to_owned()
            .map(|c| serde_json::from_value(c).unwrap());
        EventInstance {
            id: self.id.to_proto_id(),
            event_id: self.event_id.to_proto_id(),
            post: post.map(|p| p.to_proto(author.as_deref(), None, media_lookup)),
            starts_at: Some(self.starts_at.to_proto()),
            ends_at: Some(self.ends_at.to_proto()),
            info: Some(EventInstanceInfo {
                ..Default::default()
            }),
            location: location,
            ..Default::default()
        }
    }
}
