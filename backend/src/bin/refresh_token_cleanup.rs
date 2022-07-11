// use db_connection;
// use models;
// mod db_connection;
extern crate jonline;
extern crate diesel;
use diesel::*;
use jonline::db_connection;
use jonline::schema::user_refresh_tokens::dsl as user_refresh_tokens;

pub fn main() {
  println!("Connecting to DB...");
    let conn = db_connection::establish_connection();
    println!("Deleting Expired Tokens...");
    delete(
      user_refresh_tokens::user_refresh_tokens
          .filter(user_refresh_tokens::expires_at.lt(diesel::dsl::now)),
  )
  .execute(&conn)
  .unwrap_or(0);
  println!("Done.");
}