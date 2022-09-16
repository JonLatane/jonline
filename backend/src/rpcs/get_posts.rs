use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{GetPostsRequest, Post, Posts};
use crate::schema;

// use super::validations::*;

pub fn get_posts(
    request: Request<GetPostsRequest>,
    _user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<Response<Posts>, Status> {
    println!("GetPosts called");
    let req: GetPostsRequest = request.into_inner();
    let posts = match req.to_owned().post_id {
        Some(post_id) => {
            get_by_post_id(&post_id, conn)?
        }
        None => get_all_posts(conn),
    };
    println!("GetPosts::request: {:?}, result: {:?}", req, posts);
    Ok(Response::new(Posts { posts: posts }))
}

fn get_by_post_id(post_id: &str, conn: &PgPooledConnection) -> Result<Vec<Post>, Status> {
    let requested_post_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => Some(db_id),
        Err(_) => return Err(Status::new(Code::InvalidArgument, "post_id_not_valid")),
    };
    let posts = schema::posts::table
        .left_join(schema::users::table.on(schema::posts::user_id.eq(schema::users::id.nullable())))
        .select((
            schema::posts::all_columns,
            schema::users::username.nullable(),
        ))
        .filter(schema::posts::published.eq(true))
        .filter(schema::posts::id.nullable().eq(requested_post_id))
        .order(schema::posts::created_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect();
    Ok(posts)
}

fn get_all_posts(
    conn: &PgPooledConnection,
) -> Vec<Post> {
    schema::posts::table
            .left_join(
                schema::users::table.on(schema::posts::user_id.eq(schema::users::id.nullable())),
            )
            .select((
                (
                    schema::posts::id,
                    schema::posts::user_id,
                    schema::posts::parent_post_id,
                    schema::posts::title,
                    schema::posts::link,
                    schema::posts::content,
                    schema::posts::published,
                    schema::posts::created_at,
                    schema::posts::updated_at,
                    schema::posts::reply_count,
                ),
                schema::users::username.nullable(),
            ))
            .filter(schema::posts::published.eq(true))
            .order(schema::posts::created_at.desc())
            .limit(100)
            .load::<(models::MinimalPost, Option<String>)>(conn)
            .unwrap()
            .iter()
            .map(|(post, username)| post.to_proto(username.to_owned()))
            .collect()
}
