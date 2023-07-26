use std::collections::HashMap;
use std::mem::transmute;

use diesel::*;
use itertools::Itertools;
use tonic::Code;
use tonic::Status;

use super::{MediaLookup, ToI32Moderation, ToI32Visibility, ToLink, ToProtoId, ToProtoTime};
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::models::MarshalablePost;
use crate::protos::*;
use crate::rpcs::validations::PASSING_MODERATIONS;
use crate::schema::{group_posts, groups, posts, users};

pub fn convert_posts(
    data: &Vec<MarshalablePost>,
    reply_depth: u32,
    user: &Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Vec<Post> {
    let mut media_ids = data
        .iter()
        .map(|post| post.0.media.iter())
        .flatten()
        .map(|media| *media)
        .collect::<Vec<i64>>();

    let post_children: HashMap<i64, Vec<MarshalablePost>> = if reply_depth <= 1 {
        HashMap::new()
    } else {
        data.iter()
            .map(|data| {
                let post = &data.0;
                if post.reply_count == 0 {
                    return (post.id, vec![]);
                }
                let replies = posts::table
                    .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
                    .select((posts::all_columns, users::username.nullable()))
                    // .filter(posts::visibility.eq(Visibility::GlobalPublic.as_str_name()))
                    .filter(posts::visibility.ne(Visibility::Private.as_str_name()))
                    .filter(posts::parent_post_id.eq(post.id))
                    .order(posts::created_at.desc())
                    .limit(100)
                    .load::<(models::Post, Option<String>)>(conn)
                    .unwrap()
                    .iter()
                    .map(|(reply, username)| {
                        media_ids.extend(reply.media.iter());
                        MarshalablePost(reply.clone(), username.clone(), None)
                    })
                    .collect();

                (post.id, replies)
            })
            .collect()
    };

    let media_references: MediaLookup = models::get_all_media(media_ids, conn)
        .unwrap_or_else(|e| {
            log::error!("Error getting media references: {:?}", e);
            vec![]
        })
        .iter()
        .map(|media| (media.id, media))
        .collect();

    let mut posts = vec![];
    for MarshalablePost(post, username, group_post) in data {
        let post = post.to_proto(
            username.to_owned(),
            group_post.as_ref(),
            Some(&media_references),
        );
        posts.push(post);
    }
    posts
}

pub trait ToProtoPost {
    fn to_proto(
        &self,
        author: Option<&models::Author>,
        group_post: Option<&models::GroupPost>,
        media_lookup: Option<&MediaLookup>,
    ) -> Post;
    fn proto_author(&self, author: Option<String>) -> Option<Author>;
}

impl ToProtoPost for models::Post {
    fn to_proto(
        &self,
        author: Option<&models::Author>,
        group_post: Option<&models::GroupPost>,
        media_lookup: Option<&MediaLookup>,
    ) -> Post {
        Post {
            id: self.id.to_proto_id(),
            reply_to_post_id: self.parent_post_id.map(|i| i.to_proto_id()),
            author: self.proto_author(username),

            title: self.title.to_owned(),
            link: self.link.to_link(),
            content: self.content.to_owned(),

            response_count: self.response_count,
            reply_count: self.reply_count,
            group_count: self.group_count,
            current_group_post: group_post.map(|gp| gp.to_proto()),
            media: match media_lookup {
                Some(lookup) => self
                    .media
                    .iter()
                    .map(|v| match lookup.get(v) {
                        Some(media) => Some(media.to_proto()),
                        None => None,
                    })
                    .filter(|v| v.is_some())
                    .map(|v| v.unwrap())
                    .collect_vec(),
                None => vec![],
            }, // self.media.iter().map(|v| v.to_proto_id()).collect_vec(),
            media_generated: self.media_generated,
            embed_link: self.embed_link,
            shareable: self.shareable,

            context: self.context.to_i32_post_context(),
            visibility: self.visibility.to_i32_visibility(),
            moderation: self.moderation.to_i32_moderation(),

            replies: vec![], //TODO update this

            created_at: Some(self.created_at.to_proto()),
            updated_at: self.updated_at.map(|t| t.to_proto()),
            published_at: self.published_at.map(|t| t.to_proto()),
            last_activity_at: Some(self.last_activity_at.to_proto()),
        }
    }
    fn proto_author(
        &self,
        author: Option<&models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> Option<Author> {
        self.user_id.map(|user_id| Author {
            user_id: user_id.to_proto_id(),
            username: author.username,
            avatar: media_lookup.map,
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
            group_moderation: self.group_moderation.to_i32_moderation(),
            created_at: Some(self.created_at.to_proto()),
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
