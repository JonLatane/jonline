extern crate diesel;
extern crate jonline;

use diesel::*;

use jonline::db_connection;
use jonline::schema::posts::dsl::*;

pub fn main() {
    println!("Deleting all preview images...");
    println!("Connecting to DB...");
    let mut conn = db_connection::establish_connection();
    update(posts)
        .set(preview.eq(None::<Vec<u8>>))
        .execute(&mut conn)
        .unwrap();

    println!("Done deleting preview images.");
}
