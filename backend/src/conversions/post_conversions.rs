use tonic::Status;

use super::id_conversions::ToProtoId;
use super::visibility_moderation_conversions::ToProtoModeration;
use super::ToLink;
use super::ToProtoVisibility;
use super::ToProtoTime;
use crate::db_connection::PgPooledConnection;
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
            created_at: Some(self.created_at.to_proto()),
            updated_at: self.updated_at.map(|t| t.to_proto()),
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
            visibility: self
                .visibility
                .to_proto_visibility()
                .unwrap_or(Visibility::Unknown) as i32,
            moderation: self
                .moderation
                .to_proto_moderation()
                .unwrap_or(Moderation::Unknown) as i32,
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


pub trait ToProtoGroupPost {
    fn to_proto(&self) -> GroupPost;
    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status>;
}
impl ToProtoGroupPost for models::GroupPost {
    fn to_proto(&self) -> GroupPost {
        return GroupPost {
            group_id: self.group_id.to_proto_id().to_string(),
            post_id: self.post_id.to_proto_id().to_string(),
            user_id: self.user_id.to_proto_id().to_string(),
            group_moderation: self.group_moderation.to_proto_moderation().unwrap() as i32,
            created_at: Some(self.created_at.to_proto()),
            // updated_at: Some(self.updated_at.to_proto()),
        };
    }

    fn update_related_counts(&self, _conn: &mut PgPooledConnection) -> Result<(), Status> {
        //Notthing to do here yet!
                Ok(())
    }
}
