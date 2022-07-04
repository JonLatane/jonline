use crate::db_connection::*;
use crate::protos::*;
use tonic::{Request, Response, Status};

use std::time;

pub fn get_post(
    _conn: &PgPooledConnection,
    request: Request<GetPostRequest>,
) -> Result<Response<Post>, Status> {
    println!("Request from {:?}", request.remote_addr());
    let now_as_secs = time::SystemTime::now()
        .duration_since(time::UNIX_EPOCH)
        .expect("Time went backwards")
        .as_secs() as i64;

    let response = Post {
        id: request.into_inner().id,
        author: Some(post::Author {
            user_id: "generated-user-id".to_owned(),
            username: "Peter".to_owned(),
        }),
        created_at: Some(prost_types::Timestamp {
            seconds: now_as_secs,
            nanos: 0,
        }),
        updated_at: Some(prost_types::Timestamp {
            seconds: now_as_secs,
            nanos: 0,
        }),
        title: "Zero to One".to_owned(),
        content: "Hello hello hello".to_owned(),
        links: [].to_vec(),
    };
    Ok(Response::new(response))
}
