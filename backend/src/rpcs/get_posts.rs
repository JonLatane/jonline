use diesel::*;
use tonic::{Code, Request, Response, Status};

use crate::conversions::*;
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::{GetPostsRequest, Post, Posts};
use crate::schema::{posts, users};

// use super::validations::*;

pub fn get_posts(
    request: Request<GetPostsRequest>,
    _user: Option<models::User>,
    conn: &PgPooledConnection,
) -> Result<Response<Posts>, Status> {
    // println!("GetPosts called");
    let req: GetPostsRequest = request.into_inner();
    let result = match req.to_owned().post_id {
        Some(post_id) => get_by_post_id(&post_id, conn)?,
        None => match req.to_owned().replies_to_post_id {
            Some(post_id) => get_replies_to_post_id(&post_id, conn)?,
            None => get_all_posts(conn),
        },
    };
    println!("GetPosts::request: {:?}, result: {:?}", req, result);
    Ok(Response::new(Posts { posts: result }))
}

fn get_by_post_id(post_id: &str, conn: &PgPooledConnection) -> Result<Vec<Post>, Status> {
    let post_db_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => return Err(Status::new(Code::InvalidArgument, "post_id_invalid")),
    };
    let result = posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((posts::all_columns, users::username.nullable()))
        .filter(posts::visibility.eq("GLOBAL_PUBLIC"))
        .filter(posts::id.eq(post_db_id))
        .order(posts::created_at.desc())
        .limit(1)
        .load::<(models::Post, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect();
    Ok(result)
}

fn get_all_posts(conn: &PgPooledConnection) -> Vec<Post> {
    posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
        .filter(posts::visibility.eq("GLOBAL_PUBLIC"))
        .filter(posts::parent_post_id.is_null())
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect()
}

fn get_replies_to_post_id(post_id: &str, conn: &PgPooledConnection) -> Result<Vec<Post>, Status> {
    let post_db_id = match post_id.to_string().to_db_id() {
        Ok(db_id) => db_id,
        Err(_) => {
            return Err(Status::new(
                Code::InvalidArgument,
                "replies_to_post_id_invalid",
            ))
        }
    };
    let result = posts::table
        .left_join(users::table.on(posts::user_id.eq(users::id.nullable())))
        .select((models::MINIMAL_POST_COLUMNS, users::username.nullable()))
        .filter(posts::visibility.eq("GLOBAL_PUBLIC"))
        .filter(posts::parent_post_id.eq(post_db_id))
        .order(posts::created_at.desc())
        .limit(100)
        .load::<(models::MinimalPost, Option<String>)>(conn)
        .unwrap()
        .iter()
        .map(|(post, username)| post.to_proto(username.to_owned()))
        .collect();
    Ok(result)
}
