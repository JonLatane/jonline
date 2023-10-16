use tonic::{Code, Status};

use crate::{
    db_connection::PgPooledConnection, marshaling::ToDbId, models, models::get_event, protos::*,
};

pub fn delete_event(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event = get_event(
        request.id.to_db_id_or_err("id")?,
        &Some(current_user.clone()),
        conn,
    )?;
    request.post.map_or_else(
        || {
            Err(Status::new(
                Code::InvalidArgument,
                "event must contain associated post",
            ))
        },
        |post| match post.id.to_db_id_or_err("post.id")? {
            post_id if post_id == event.post_id => super::delete_post(post, current_user, conn)
                .map(|deleted_post| Event {
                    post: Some(deleted_post),
                    ..request
                }),
            _ => Err(Status::new(
                Code::InvalidArgument,
                "post ID mismatches event post ID",
            )),
        },
    )
}
