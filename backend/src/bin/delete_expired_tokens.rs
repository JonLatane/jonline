extern crate diesel;
extern crate jonline;
use diesel::*;
use jonline::db_connection;
use jonline::schema::user_refresh_tokens::dsl as user_refresh_tokens;
use jonline::schema::user_access_tokens::dsl as user_access_tokens;

pub fn main() {
    println!("Cleaning Expired Tokens...");
    println!("Connecting to DB...");
    let mut conn = db_connection::establish_connection();
    println!("Deleting Expired Refresh Tokens...");
    delete(
        user_access_tokens::user_access_tokens
            .filter(user_access_tokens::expires_at.lt(diesel::dsl::now)),
    )
    .execute(&mut conn)
    .unwrap_or(0);
    println!("Deleting Expired Auth Tokens...");
    delete(
        user_refresh_tokens::user_refresh_tokens
            .filter(user_refresh_tokens::expires_at.lt(diesel::dsl::now)),
    )
    .execute(&mut conn)
    .unwrap_or(0);
    println!("Done Cleaning Expired Tokens.");
}
