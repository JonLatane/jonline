use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::posts::dsl::{id as post_id, posts, unauthenticated_star_count};

pub fn star_post(
    request: Post,
    _user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<Post, Status> {
    diesel::update(posts)
        .filter(post_id.eq(request.id.to_db_id_or_err("invalid_post_id")?))
        .set(unauthenticated_star_count.eq(unauthenticated_star_count + 1))
        .execute(conn)
        .map_err(|_| Status::new(Code::Aborted, "unstar_failed"))?;
    let updated_star_count = posts
        .select(unauthenticated_star_count)
        .filter(post_id.eq(request.id.to_db_id_or_err("invalid_post_id")?))
        .first::<i64>(conn)
        .map_err(|_| Status::new(Code::Aborted, "unstar_failed"))?;
    Ok(Post {
        unauthenticated_star_count: updated_star_count,
        ..request
    })
}
