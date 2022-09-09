use diesel::*;
use tonic::{Request, Response, Status, Code};

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
    let req = request.into_inner();
    validate_length(&req.title, "title", 4, 255)?;
    let parent_post_db_id: Option<i32> = match req.reply_to_post_id {
        None => None,
        Some(proto_id) => {
            match proto_id.to_db_id() {
                Ok(db_id) => Some(db_id),
                Err(_) => return Err(Status::new(Code::InvalidArgument, "invalid_reply_to_post_id")),
            }
        }
    };

    let new_posts = vec![models::NewPost {
        user_id: Some(user.id),
        parent_post_id: parent_post_db_id,
        title: req.title.to_owned(),
        link: req.link.to_owned(),
        content: req.content.to_owned(),
        published: true,
    }];

    let inserted_posts = insert_into(posts)
        .values(&new_posts)
        .get_results::<models::Post>(conn)
        .unwrap();

    return Ok(Response::new(inserted_posts[0].to_proto(Some(user.username))));
}
