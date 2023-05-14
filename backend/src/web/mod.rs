
use std::sync::Arc;

use crate::db_connection::PgPool;

pub struct RocketState {
  pub pool: Arc<PgPool>,
  pub bucket: Arc<s3::Bucket>,
  pub tempdir: Arc<tempfile::TempDir>,
}
// This module contains Rocket routes and handlers for the web interface.

pub mod headers;
pub mod cors;

pub mod catchers;
pub use catchers::*;

pub mod flutter_web;
pub use flutter_web::*;

pub mod tamagui_web;
pub use tamagui_web::*;

pub mod main_index;
pub use main_index::*;

pub mod secure_redirect;
pub use secure_redirect::*;

pub mod robots_sitemap;
pub use robots_sitemap::*;

pub mod media;
pub use media::*;