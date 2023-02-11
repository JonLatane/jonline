extern crate diesel;
extern crate jonline;

use diesel::*;

use jonline::db_connection;
use jonline::schema::posts::dsl::*;

pub fn main() {
    log::info!("Deleting all preview images...");
    log::info!("Connecting to DB...");
    let mut conn = db_connection::establish_connection();
    update(posts)
        .set(preview.eq(None::<Vec<u8>>))
        .execute(&mut conn)
        .unwrap();

    log::info!("Done deleting preview images.");
}
