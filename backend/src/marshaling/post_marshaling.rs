use std::mem::transmute;

use diesel::*;
use itertools::Itertools;
use tonic::Code;
use tonic::Status;

use super::{
    load_media_lookup, MediaLookup, ToI32Moderation, ToI32Visibility, ToLink, ToProtoAuthor,
    ToProtoId, ToProtoMediaReference, ToProtoTime,
};
use crate::db_connection::PgPooledConnection;
use crate::models;

use crate::protos::*;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::{group_posts, groups, posts};

#[derive(Debug, Clone)]
pub struct MarshalablePost(
    pub models::Post,
    pub Option<models::Author>,
    pub Option<models::GroupPost>,
    pub Option<models::Author>, // GroupPost author
    pub Vec<MarshalablePost>,
);

pub fn convert_posts(data: &Vec<MarshalablePost>, conn: &mut PgPooledConnection) -> Vec<Post> {
    let media_ids: Vec<i64> = data
        .iter()
        .map(|ref post| {
            let mut ids = post.0.media.to_owned();
            post.1
                .as_ref()
                .map(|a| a.avatar_media_id.map(|id| ids.push(Some(id))));
            post.3
                .as_ref()
                .map(|a| a.avatar_media_id.map(|id| ids.push(Some(id))));
            post.4.iter().for_each(|reply| {
                ids.extend(reply.0.media.iter());
                reply
                    .1
                    .as_ref()
                    .map(|a| a.avatar_media_id.map(|id| ids.push(Some(id))));
            });
            ids
        })
        .flatten()
        .filter(|v| v.is_some())
        .map(|v| v.unwrap())
        .collect();

    let lookup = load_media_lookup(media_ids, conn);

    data.iter()
        .map(|marshalable_post| marshalable_post.to_proto(lookup.as_ref()))
        .collect()
}

pub trait ToProtoMarshalablePost {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> Post;
}

impl ToProtoMarshalablePost for MarshalablePost {
    fn to_proto(&self, media_lookup: Option<&MediaLookup>) -> Post {
        let post = &self.0;
        let author = &self.1;
        let group_post = &self.2;
        let replies = self.4.to_owned();
        Post {
            id: post.id.to_proto_id(),
            reply_to_post_id: post.parent_post_id.map(|i| i.to_proto_id()),
            author: author.as_ref().map(|a| a.to_proto(media_lookup)),

            title: post.title.to_owned(),
            link: post.link.to_link(),
            content: post.content.to_owned(),

            response_count: post.response_count,
            reply_count: post.reply_count,
            group_count: post.group_count,
            unauthenticated_star_count: post.unauthenticated_star_count,
            current_group_post: group_post
                .as_ref()
                .map(|gp| gp.to_proto(author, media_lookup)),
            media: match media_lookup {
                Some(lookup) => post
                    .media
                    .iter()
                    .map(|v| match v {
                        Some(v) => match lookup.get(v) {
                            Some(media) => Some(media.to_proto()),
                            None => None,
                        },
                        None => None,
                    })
                    .filter(|v| v.is_some())
                    .map(|v| v.unwrap())
                    .collect_vec(),
                None => vec![],
            }, // self.media.iter().map(|v| v.to_proto_id()).collect_vec(),
            media_generated: post.media_generated,
            embed_link: post.embed_link,
            shareable: post.shareable,

            context: post.context.to_i32_post_context(),
            visibility: post.visibility.to_i32_visibility(),
            moderation: post.moderation.to_i32_moderation(),

            replies: replies
                .iter()
                .map(|r| r.to_proto(media_lookup))
                .collect_vec(),

            created_at: Some(post.created_at.to_proto()),
            updated_at: post.updated_at.map(|t| t.to_proto()),
            published_at: post.published_at.map(|t| t.to_proto()),
            last_activity_at: Some(post.last_activity_at.to_proto()),
        }
    }
}

pub trait ToProtoGroupPost {
    fn to_proto(
        &self,
        author: &Option<models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> GroupPost;
    fn update_related_counts(&self, conn: &mut PgPooledConnection) -> Result<(), Status>;
}
impl ToProtoGroupPost for models::GroupPost {
    fn to_proto(
        &self,
        author: &Option<models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> GroupPost {
        return GroupPost {
            group_id: self.group_id.to_proto_id().to_string(),
            post_id: self.post_id.to_proto_id().to_string(),
            user_id: self.user_id.to_proto_id().to_string(),
            group_moderation: self.group_moderation.to_i32_moderation(),
            created_at: Some(self.created_at.to_proto()),
            shared_by: author.as_ref().map(|a| a.to_proto(media_lookup)),
            // updated_at: self.updated_at.map(|t| t.to_proto()),
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

pub const ALL_POST_CONTEXTS: [PostContext; 4] = [
    PostContext::Post,
    PostContext::Reply,
    PostContext::Event,
    PostContext::EventInstance,
];
pub trait ToStringPostContext {
    fn to_string_post_context(&self) -> String;
}
impl ToStringPostContext for PostContext {
    fn to_string_post_context(&self) -> String {
        self.as_str_name().to_string()
    }
}

pub trait ToProtoPostContext {
    fn to_proto_post_context(&self) -> Option<PostContext>;
}
impl ToProtoPostContext for String {
    fn to_proto_post_context(&self) -> Option<PostContext> {
        for post_context in ALL_POST_CONTEXTS {
            if post_context.as_str_name().eq_ignore_ascii_case(self) {
                return Some(post_context);
            }
        }
        return None;
    }
}
impl ToProtoPostContext for i32 {
    fn to_proto_post_context(&self) -> Option<PostContext> {
        Some(unsafe { transmute::<i32, PostContext>(*self) })
    }
}

pub trait ToI32PostContext {
    fn to_i32_post_context(&self) -> i32;
}
impl ToI32PostContext for String {
    fn to_i32_post_context(&self) -> i32 {
        self.to_proto_post_context().unwrap() as i32
    }
}
