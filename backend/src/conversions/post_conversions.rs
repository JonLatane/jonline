use super::id_conversions::ToProtoId;
use crate::models;
use crate::protos::*;

pub trait ToProtoPost {
    fn to_proto(&self, username: Option<String>) -> Post;
    fn proto_author(&self, username: Option<String>) -> Option<post::Author>;
}
impl ToProtoPost for models::Post {
    fn to_proto(&self, username: Option<String>) -> Post {
        Post {
            id: self.id.to_proto_id(),
            title: self.title.to_owned(),
            link: self.link.to_owned(),
            content: self.content.to_owned(),
            created_at: Some(::prost_types::Timestamp {
                seconds: 1,
                nanos: 1,
            }),
            updated_at: None,
            author: self.proto_author(username),
            reply_count: self.reply_count
        }
    }
    fn proto_author(&self, username: Option<String>) -> Option<post::Author> {
        self.user_id.map(|user_id| post::Author {
            user_id: user_id.to_proto_id(),
            username: username,
        })
    }
}
