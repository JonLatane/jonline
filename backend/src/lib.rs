#[macro_use]
extern crate diesel;
extern crate dotenv;
#[macro_use]
extern crate diesel_migrations;
extern crate bcrypt;
extern crate bs58;
extern crate ring;

pub mod auth;
pub mod db_connection;
pub mod jonline;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;

pub fn report_error<E: 'static>(err: E)
where
    E: std::error::Error,
    E: Send + Sync,
{
    eprintln!("[ERROR] {}", err);
    if let Some(cause) = err.source() {
        eprintln!();
        eprintln!("Caused by:");
        for (i, e) in std::iter::successors(Some(cause), |e| e.source()).enumerate() {
            eprintln!("   {}: {}", i, e);
        }
    }
}
