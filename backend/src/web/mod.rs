
use std::sync::Arc;

use crate::db_connection::PgPool;

pub struct RocketState {
  pub pool: Arc<PgPool>,
}
// This module contains Rocket routes and handlers for the web interface.

pub mod catchers;
pub use catchers::*;

pub mod web_macros;
pub use web_macros::*;

pub mod styles;
pub use styles::*;

pub mod assets;
pub use assets::*;

pub mod home_page;
pub use home_page::*;
pub mod post_page;
pub use post_page::*;

pub mod flutter_web;
pub use flutter_web::*;


pub mod main_index;
pub use main_index::*;
