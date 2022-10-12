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
    println!("ResetData called");
    validate_permission(&user, Permission::Admin)?;

    let result = conn.transaction::<(), diesel::result::Error, _>(|conn| {
        delete(posts::table).execute(conn)?;
        delete(groups::table).execute(conn)?;
        delete(users::table).filter(users::id.ne(user.id)).execute(conn)?;
        update(users::table).set((users::follower_count.eq(0), users::following_count.eq(0))).execute(conn)?;
        Ok(())
    });
    match result {
        Ok(()) => {
            println!("Data successfully reset.");
            Ok(())
        },
        Err(e) => {
            println!("Data reset failed. Error: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating"))},
    }
}
