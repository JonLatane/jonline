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
    let req = request.into_inner();
    validate_length(&req.title, "title", 4, 255)?;
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

    let result = conn.transaction::<Response<Post>, diesel::result::Error, _>(|| {
        let inserted_post = insert_into(posts)
            .values(&models::NewPost {
                user_id: Some(user.id),
                parent_post_id: parent_post_db_id,
                title: req.title.to_owned(),
                link: req.link.to_owned(),
                content: req.content.to_owned(),
                published: true,
            })
            .get_results::<models::Post>(conn)?[0]
            .to_proto(Some(user.username));
        match parent_post_db_id {
            Some(parent_post_db_id) => match update(posts)
                .filter(parent_post_id.eq(Some(parent_post_db_id)))
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
        Ok(Response::new(inserted_post))
    });

    match result {
        Ok(response) => Ok(response),
        Err(_) => Err(Status::new(Code::Internal, "internal_error")),
    }
}
