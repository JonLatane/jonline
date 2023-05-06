use super::{ToI32Moderation, ToI32Visibility, ToProtoId, ToProtoTime};
use crate::models;
use crate::protos::*;

pub trait ToProtoMedia {
    fn to_proto(&self) -> Media;
}

impl ToProtoMedia for models::Media {
    fn to_proto(&self) -> Media {
        Media {
            id: self.id.to_proto_id(),
            user_id: self.user_id.map(|i| i.to_proto_id()),
            name: self.name.to_owned(),
            description: self.description.to_owned(),
            visibility: self.visibility.to_i32_visibility(),
            moderation: self.moderation.to_i32_moderation(),
            created_at: Some(self.created_at.to_proto()),
            updated_at: Some(self.updated_at.to_proto()),
        }
    }
}
