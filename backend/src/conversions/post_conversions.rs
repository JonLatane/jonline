use super::ToLink;
use super::ToProtoVisibility;
use super::id_conversions::ToProtoId;
use super::visibility_moderation_conversions::ToProtoModeration;
use crate::models;
use crate::protos::*;

pub trait ToProtoPost {
    fn to_proto(&self, username: Option<String>) -> Post;
    fn proto_author(&self, username: Option<String>) -> Option<post::Author>;
}
impl ToProtoPost for models::MinimalPost {
    fn to_proto(&self, username: Option<String>) -> Post {
        Post {
            id: self.id.to_proto_id(),
            reply_to_post_id: self.parent_post_id.map(|i| i.to_proto_id()),
            title: self.title.to_owned(),
            link: self.link.to_link(),
            content: self.content.to_owned(),
            created_at: Some(::prost_types::Timestamp {
                seconds: 1,
                nanos: 1,
            }),
            updated_at: None,
            author: self.proto_author(username),
            response_count: self.response_count,
            preview_image: None,
            ..Default::default()
        }
    }
    fn proto_author(&self, username: Option<String>) -> Option<post::Author> {
        self.user_id.map(|user_id| post::Author {
            user_id: user_id.to_proto_id(),
            username: username,
        })
    }
}

impl ToProtoPost for models::Post {
    fn to_proto(&self, username: Option<String>) -> Post {
        Post {
            id: self.id.to_proto_id(),
            reply_to_post_id: self.parent_post_id.map(|i| i.to_proto_id()),
            title: self.title.to_owned(),
            link: self.link.to_link(),
            content: self.content.to_owned(),
            created_at: Some(::prost_types::Timestamp {
                seconds: 1,
                nanos: 1,
            }),
            updated_at: None,
            author: self.proto_author(username),
            response_count: self.response_count,
            reply_count: self.reply_count,
            preview_image: self.preview.to_owned(),
            visibility: self.visibility.to_proto_visibility().unwrap_or(0),
            moderation: self.moderation.to_proto_moderation().unwrap_or(0),
            replies: vec![], //TODO update this
        }
    }
    fn proto_author(&self, username: Option<String>) -> Option<post::Author> {
        self.user_id.map(|user_id| post::Author {
            user_id: user_id.to_proto_id(),
            username: username,
        })
    }
}
