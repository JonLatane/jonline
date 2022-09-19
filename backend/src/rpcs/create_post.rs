use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{CreatePostRequest, Post};
use crate::schema::posts::dsl::*;

use super::validations::*;

pub fn create_post(
    request: Request<CreatePostRequest>,
    user: models::User,
    conn: &PgPooledConnection,
) -> Result<Response<Post>, Status> {
    println!(
        "CreatePost called for user {}, user_id={}",
        &user.username, user.id
    );
    let req = request.into_inner();
    match req.title.to_owned() {
        None => (),
        Some(other_title) => validate_length(&other_title, "title", 4, 255)?,
    }
    // validate_length(&req.title, "title", 4, 255)?;
    validate_max_length(req.link.to_owned(), "link", 10000)?;
    validate_max_length(req.content.to_owned(), "content", 10000)?;

    let parent_post_db_id: Option<i32> = match req.reply_to_post_id {
        None => None,
        Some(proto_id) => match proto_id.to_db_id() {
            Ok(db_id) => Some(db_id),
            Err(_) => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "replying_to_nonexistent_post",
                ))
            }
        },
    };

    let parent_post_title: Option<String> = match parent_post_db_id {
        None => None,
        Some(parent_id) => posts.select(title).find(parent_id).first(conn).ok(),
    };

    let post_title: String = parent_post_title
        .or(req.title.to_owned())
        .ok_or(Status::new(
            Code::Internal,
            "title_or_reply_to_post_id_required",
        ))?;

    let post = conn.transaction::<models::Post, diesel::result::Error, _>(|| {
        let inserted_post = insert_into(posts)
            .values(&models::NewPost {
                user_id: Some(user.id),
                parent_post_id: parent_post_db_id,
                title: post_title,
                link: req.link.to_link(),
                content: req.content.to_owned(),
                published: true,
                preview: None,
            })
            .get_result::<models::Post>(conn)?;
        match parent_post_db_id {
            Some(parent_post_db_id) => match update(posts)
                .filter(id.eq(parent_post_db_id))
                .set(reply_count.eq(reply_count + 1))
                .execute(conn)?
            {
                // This error should be impossible given that the
                // above insert would hit a foreign key constraint.
                0 => Err(diesel::result::Error::NotFound),
                _ => Ok(()),
            }?,
            None => (),
        }
        Ok(inserted_post)
    });

    match post {
        Ok(post) => {
            println!("Post created! Result: {:?}", post);
            Ok(Response::new(post.to_proto(Some(user.username))))
        }
        Err(e) => {
            println!("Error creating post! {:?}", e);
            Err(Status::new(Code::Internal, "internal_error"))        },
    }
}
