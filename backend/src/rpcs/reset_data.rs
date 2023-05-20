use crate::db_connection::PgPooledConnection;
use diesel::*;
use tonic::{Code, Status};

use crate::models;
use crate::protos::*;
use crate::schema::*;
use super::validations::*;

pub fn reset_data(
    user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    log::info!("ResetData called");
    validate_permission(&user, Permission::Admin)?;

    let result = conn.transaction::<(), diesel::result::Error, _>(|conn| {
        update(media::table).set(media::user_id.eq(None::<i64>)).execute(conn)?;
        delete(user_posts::table).execute(conn)?;
        delete(group_posts::table).execute(conn)?;
        delete(posts::table).execute(conn)?;
        delete(groups::table).execute(conn)?;
        delete(follows::table).execute(conn)?;
        delete(users::table).filter(users::id.ne(user.id)).execute(conn)?;
        update(users::table).set((users::follower_count.eq(0), users::following_count.eq(0))).execute(conn)?;
        Ok(())
    });
    match result {
        Ok(()) => {
            log::info!("Data successfully reset.");
            Ok(())
        },
        Err(e) => {
            log::error!("Data reset failed. Error: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating"))},
    }
}
