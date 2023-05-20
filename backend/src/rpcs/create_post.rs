use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::marshaling::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{posts, users};

use super::validations::*;

pub fn create_post(
    request: Request<Post>,
    user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Response<Post>, Status> {
    log::info!(
        "CreatePost called for user {}, user_id={}",
        &user.username, user.id
    );
    validate_permission(&user, Permission::CreatePosts)?;
    let req = request.into_inner();
    match req.title.to_owned() {
        None => {}
        Some(t) => match req.reply_to_post_id {
            Some(_) => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "title_not_allowed_with_reply",
                ))
            }
            None => validate_length(&t, "title", 1, 255)?,
        },
    }
    validate_max_length(req.link.to_owned(), "link", 10000)?;
    validate_max_length(req.content.to_owned(), "content", 10000)?;
    for media_proto_id in &req.media {
        media_proto_id.to_db_id_or_err("media")?;
    }

    // Generate the list of the post's ancestors so we can increment their response_count all at once.
    let mut ancestor_post_ids: Vec<i64> = vec![];
    let parent_post_db_id: Option<i64> = match req.reply_to_post_id.to_owned() {
        Some(proto_id) => match proto_id.to_db_id() {
            Ok(db_id) => {
                let mut ppdpid: Option<i64> = Some(db_id);
                while let Some(parent_id) = ppdpid {
                    ancestor_post_ids.push(parent_id);
                    ppdpid = posts::table
                        .select(posts::parent_post_id)
                        .find(parent_id)
                        .first::<Option<i64>>(conn)
                        .unwrap();
                }
                Some(db_id)
            }
            Err(_) => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "replying_to_nonexistent_post",
                ))
            }
        },
        None => None,
    };

    let visibility = match req.visibility() {
        Visibility::Unknown => Visibility::GlobalPublic,
        v => v
    };
    match visibility {
        Visibility::GlobalPublic => validate_permission(&user, Permission::PublishPostsGlobally)?,
        Visibility::ServerPublic => validate_permission(&user, Permission::PublishPostsLocally)?,
        _ => {}
    };

    let post_title: Option<String> = match req.reply_to_post_id {
        Some(_) => None,
        None => req.to_owned().title,
    };

    let post = conn.transaction::<models::Post, diesel::result::Error, _>(|conn| {
        let inserted_post = insert_into(posts::table)
            .values(&models::NewPost {
                user_id: Some(user.id),
                parent_post_id: parent_post_db_id,
                title: post_title,
                link: req.link.to_link(),
                content: req.content.to_owned(),
                context: PostContext::Post.as_str_name().to_string(),
                visibility: visibility.to_string_visibility(),
                embed_link: req.embed_link.to_owned(),
                media: req.media.iter().map(|m: &String| m.to_db_id().unwrap()).collect(),
            })
            .get_result::<models::Post>(conn)?;
        match parent_post_db_id.to_owned() {
            Some(parent_id) => {
                update(posts::table)
                    .filter(posts::id.eq(parent_id))
                    .set(posts::reply_count.eq(posts::reply_count + 1))
                    .execute(conn)?;
                update(posts::table)
                    .filter(posts::id.eq_any(ancestor_post_ids))
                    .set((posts::response_count.eq(posts::response_count + 1), posts::last_activity_at.eq(inserted_post.created_at)))
                    .execute(conn)?;
                update(users::table)
                    .filter(users::id.eq(user.id))
                    .set(users::post_count.eq(users::post_count + 1))
                    .execute(conn)?;
            }
            None => {
                update(users::table)
                    .filter(users::id.eq(user.id))
                    .set(users::response_count.eq(users::response_count + 1))
                    .execute(conn)?;
            }
        };
        Ok(inserted_post)
    });

    match post {
        Ok(post) => {
            log::info!("Post created! PostID:{:?}", post.id);
            Ok(Response::new(post.to_proto(Some(user.username))))
        }
        Err(e) => {
            log::error!("Error creating post! {:?}", e);
            Err(Status::new(Code::Internal, "internal_error"))
        }
    }
}
