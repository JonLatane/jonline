// use std::mem::transmute;

// use diesel::*;
// use tonic::Code;
// use tonic::Status;

use super::id_marshaling::ToProtoId;
use super::ToProtoPost;

use super::ToProtoTime;
use crate::models;
use crate::protos::*;

pub trait ToProtoEvent {
    fn to_proto(
        &self,
        post: &models::Post,
        user: Option<&models::User>,
        instances: &Vec<(
            &models::EventInstance,
            Option<&models::Post>,
            Option<&models::User>
        )>,
    ) -> Event;
    // fn to_group_proto(
    //     &self,
    //     username: Option<String>,
    //     has_preview: &bool,
    //     group_post: Option<&models::GroupPost>,
    // ) -> Post;
    // fn proto_author(&self, username: Option<String>) -> Option<Author>;
}

impl ToProtoEvent for models::Event {
    fn to_proto(
        &self,
        post: &models::Post,
        user: Option<&models::User>,
        instances: &Vec<(
            &models::EventInstance,
            Option<&models::Post>,
            Option<&models::User>
        )>,
    ) -> Event {
        // self.to_group_proto(username, has_preview, None)
        Event {
            id: self.id.to_proto_id(),
            post: Some(post.to_proto(user.map(|u| u.username.to_owned()), &post.preview.is_some())),
            instances: instances.iter().map(|(i, p, u)| i.to_proto(p, u)).collect(),
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
    fn to_proto(&self, post: &Option<&models::Post>, user: &Option<&models::User>)
        -> EventInstance;
}

impl ToProtoEventInstance for models::EventInstance {
    fn to_proto(&self, post: &Option<&models::Post>, user: &Option<&models::User>) -> EventInstance {
        EventInstance {
            id: self.id.to_proto_id(),
            post: post.map(|p| p.to_proto(user.map(|u| u.username.to_owned()), &p.preview.is_some())),
            starts_at: Some(self.starts_at.to_proto()),
            ends_at: Some(self.ends_at.to_proto()),
            info: Some(EventInstanceInfo {
                ..Default::default()
            }),
            ..Default::default()
        }
    }
}
