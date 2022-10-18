
use crate::db_connection::PgPool;
pub struct RocketState {
  pub pool: PgPool,
}
// This module contains Rocket routes and handlers for the web interface.

pub mod catchers;
pub use catchers::*;

pub mod home_page;
pub use home_page::*;

pub mod flutter_web;
pub use flutter_web::*;
