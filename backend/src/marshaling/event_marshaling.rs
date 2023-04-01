// use std::mem::transmute;

// use diesel::*;
// use tonic::Code;
// use tonic::Status;

use super::ToProtoPost;
use super::id_marshaling::ToProtoId;
// use super::visibility_moderation_marshaling::ToProtoModeration;
// use super::ToLink;
// use super::ToProtoTime;
// use super::ToProtoVisibility;
// use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
// use crate::rpcs::validations::PASSING_MODERATIONS;
// use crate::schema::group_posts;
// use crate::schema::groups;
// use crate::schema::posts;

pub trait ToProtoEvent {
    fn to_proto(&self, post: &models::Post, instances: &Vec<(models::EventInstance, Option<models::Post>)>) -> Event;
    // fn to_group_proto(
    //     &self,
    //     username: Option<String>,
    //     has_preview: &bool,
    //     group_post: Option<&models::GroupPost>,
    // ) -> Post;
    // fn proto_author(&self, username: Option<String>) -> Option<Author>;
}

impl ToProtoEvent for models::Event {
    fn to_proto(&self, post: &models::Post, instances: &Vec<(models::EventInstance, Option<models::Post>)>) -> Event {
        // self.to_group_proto(username, has_preview, None)
        Event {
            id: self.id.to_proto_id(),
            post: Some(post.to_proto(None, &post.preview.is_some())),
            instances: instances.iter().map(|(i, p)| i.to_proto(p)).collect(),
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
    fn to_proto(&self, post: &Option<models::Post>) -> EventInstance;
    // fn to_group_proto(
    //     &self,
    //     username: Option<String>,
    //     has_preview: &bool,
    //     group_post: Option<&models::GroupPost>,
    // ) -> Post;
    // fn proto_author(&self, username: Option<String>) -> Option<Author>;
}

impl ToProtoEventInstance for models::EventInstance {
    fn to_proto(&self, post: &Option<models::Post>) -> EventInstance {
        // self.to_group_proto(username, has_preview, None)
        EventInstance {
            id: self.id.to_proto_id(),
            post: post.as_ref().map(|p| p.to_proto(None, &p.preview.is_some())),
            info: Some(EventInstanceInfo {
                // start_time: self.start_time.map(|t| t.to_proto()),
                // end_time: self.end_time.map(|t| t.to_proto()),
                // location: self.location.to_owned(),
                ..Default::default()
            }),
            ..Default::default()
        }
    }
}