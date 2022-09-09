use diesel::*;
use tonic::{Request, Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{GetPostsRequest, Post, Posts};
use crate::schema;

// use super::validations::*;

pub fn get_posts(
    _request: Request<GetPostsRequest>,
    _user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<Response<Posts>, Status> {
    let db_posts: Vec<(models::Post, Option<String>)> = schema::posts::table
        .left_join(schema::users::table.on(schema::posts::user_id.eq(schema::users::id.nullable())))
        .select((
            schema::posts::all_columns,
            schema::users::username.nullable(),
        ))
        .filter(schema::posts::published.eq(true))
        .order(schema::posts::created_at.desc())
        .limit(100)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap();
    let proto_posts: Vec<Post> = db_posts
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect();
    Ok(Response::new(Posts { posts: proto_posts }))
}
