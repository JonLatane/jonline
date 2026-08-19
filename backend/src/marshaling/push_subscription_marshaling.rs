use super::{ToProtoId, ToProtoTime};
use crate::models;
use crate::protos::*;

pub trait ToProtoPushSubscription {
    fn to_proto(&self) -> PushSubscription;
}

impl ToProtoPushSubscription for models::PushSubscription {
    fn to_proto(&self) -> PushSubscription {
        PushSubscription {
            id: self.id.to_proto_id(),
            endpoint: self.endpoint.clone(),
            created_at: Some(self.created_at.to_proto()),
        }
    }
}
