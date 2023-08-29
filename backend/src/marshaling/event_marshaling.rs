// use std::mem::transmute;

// use diesel::*;
// use tonic::Code;
// use tonic::Status;

use super::id_marshaling::ToProtoId;
// use super::ToProtoPost;

use super::MediaLookup;
use super::ToProtoTime;
use crate::ToProtoMarshalablePost;
use crate::db_connection::PgPooledConnection;
use crate::models;
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

pub fn convert_events(
    data: &Vec<MarshalableEvent>,
    conn: &mut PgPooledConnection,
) -> Vec<Event> {
    let mut media_ids = data
        .iter()
        .map(|marshalable_event| {
            let post = &marshalable_event.1;
            let mut ids = &post.0.media;
            post.1.map(|a| a.avatar_media_id.map(|id| ids.push(id)));
            post.3.iter().for_each(|reply| {
                ids.extend(reply.0.media.iter());
                reply.1.map(|a| a.avatar_media_id.map(|id| ids.push(id)));
            });
            ids.iter()
        })
        .flatten()
        .map(|media| *media)
        .collect::<Vec<i64>>();

    let media_references: MediaLookup = models::get_all_media(media_ids, conn)
        .unwrap_or_else(|e| {
            log::error!("Error getting media references: {:?}", e);
            vec![]
        })
        .iter()
        .map(|media| (media.id, *media))
        .collect();

    data.iter().map(|marshalable_event| marshalable_event.to_proto(Some(&media_references))).collect()
}
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
