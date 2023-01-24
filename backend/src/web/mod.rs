
use std::sync::Arc;

use crate::db_connection::PgPool;

pub struct RocketState {
  pub pool: Arc<PgPool>,
}
// This module contains Rocket routes and handlers for the web interface.

pub mod catchers;
pub use catchers::*;

pub mod flutter_web;
pub use flutter_web::*;

pub mod tamagui_web;
pub use tamagui_web::*;

pub mod main_index;
pub use main_index::*;
