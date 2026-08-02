use crate::db_connection::PgPool;
use std::sync::Arc;

pub struct RocketState {
    pub pool: Arc<PgPool>,
    pub bucket: Arc<s3::Bucket>,
    pub tempdir: Arc<tempfile::TempDir>,
}
