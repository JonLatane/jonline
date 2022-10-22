use tonic::Code;
use tonic::Status;
use diesel::*;

use super::id_conversions::ToProtoId;
use super::visibility_moderation_conversions::ToProtoModeration;
use super::ToLink;
use super::ToProtoVisibility;
use super::ToProtoTime;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::group_posts;
use crate::schema::groups;
use crate::schema::posts;

pub trait ToProtoPost {
    fn to_proto(&self, username: Option<String>) -> Post;
    fn proto_author(&self, username: Option<String>) -> Option<Author>;
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
    fn proto_author(&self, username: Option<String>) -> Option<Author> {
        self.user_id.map(|user_id| Author {
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
            created_at: Some(::prost_wkt_types::Timestamp {
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
            current_group_post: None, //TODO update this
        }
    }
    fn proto_author(&self, username: Option<String>) -> Option<Author> {
        self.user_id.map(|user_id| Author {
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

    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status> {
        let post_count = group_posts::table
            .count()
            .filter(group_posts::group_id.eq(self.group_id))
            .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;
        diesel::update(groups::table)
            .filter(groups::id.eq(self.group_id))
            .set(groups::post_count.eq(post_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_group_post_count"))?;

        let group_count = group_posts::table
            .count()
            .filter(group_posts::post_id.eq(self.post_id))
            .filter(group_posts::group_moderation.eq_any(PASSING_MODERATIONS))
            .first::<i64>(conn)
            .unwrap() as i32;
        diesel::update(posts::table)
            .filter(posts::id.eq(self.post_id))
            .set(posts::group_count.eq(group_count))
            .execute(conn)
            .map_err(|_| Status::new(Code::Internal, "error_updating_post_group_count"))?;

        Ok(())
    }
}
