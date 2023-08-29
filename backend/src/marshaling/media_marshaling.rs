use std::collections::HashMap;

use super::{ToI32Moderation, ToI32Visibility, ToProtoId, ToProtoTime};
use crate::models;
use crate::protos::*;

pub type MediaLookup = HashMap<i64, models::MediaReference>;
// pub use MediaLookupType as MediaLookup;
pub fn media_lookup(media: Vec<models::MediaReference>) -> MediaLookup {
    media.iter().map(|m| (m.id, m.to_owned())).collect()
}

pub trait FindMedia {
    fn find_media(&self, media_id: i64) -> Option<&models::MediaReference>;
}

impl FindMedia for MediaLookup {
    fn find_media(&self, media_id: i64) -> Option<&models::MediaReference> {
        self.get(&media_id)
    }
}

impl FindMedia for Option<&MediaLookup> {
    fn find_media(&self, media_id: i64) -> Option<&models::MediaReference> {
        self.map(|lookup| lookup.get(&media_id)).flatten()
    }
}

pub trait ToProtoMedia {
    fn to_proto(&self) -> Media;
}

impl ToProtoMedia for models::Media {
    fn to_proto(&self) -> Media {
        Media {
            id: self.id.to_proto_id(),
            content_type: self.content_type.to_owned(),
            user_id: self.user_id.map(|i| i.to_proto_id()),
            name: self.name.to_owned(),
            description: self.description.to_owned(),
            visibility: self.visibility.to_i32_visibility(),
            moderation: self.moderation.to_i32_moderation(),
            generated: self.generated,
            processed: self.processed,
            created_at: Some(self.created_at.to_proto()),
            updated_at: Some(self.updated_at.to_proto()),
        }
    }
}

pub trait ToProtoMediaReference {
    fn to_proto(&self) -> MediaReference;
}

impl ToProtoMediaReference for models::MediaReference {
    fn to_proto(&self) -> MediaReference {
        MediaReference {
            id: self.id.to_proto_id(),
            content_type: self.content_type.to_owned(),
            name: self.name.to_owned(),
        }
    }
}
