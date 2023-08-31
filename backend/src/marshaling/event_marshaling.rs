use super::{load_media_lookup, MediaLookup, ToProtoId, ToProtoMarshalablePost, ToProtoTime};
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
