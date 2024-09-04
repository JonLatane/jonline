use std::env;

#[macro_use]
extern crate diesel;
extern crate bcrypt;
extern crate bs58;
extern crate diesel_migrations;
extern crate dotenv;
extern crate futures;
extern crate itertools;
extern crate ring;
extern crate serde;
extern crate serde_json;
extern crate tonic_web;
extern crate uuid;
#[macro_use]
extern crate lazy_static;
extern crate awscreds;
// extern crate awsregion;
extern crate bytes;
extern crate env_logger;
extern crate http;
extern crate log;
extern crate percent_encoding;
extern crate reqwest;
extern crate s3;
extern crate tempfile;
extern crate tokio_stream;

pub mod auth;
pub mod db_connection;
pub mod jonline_service;
pub mod logic;
pub mod marshaling;
pub mod minio_connection;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;
pub mod servers;
pub mod web;

pub use marshaling::*;

#[cfg(test)]
mod tests {
    use crate::marshaling::ToDbId;
    use crate::marshaling::ToProtoId;

    #[test]
    fn id_conversions_work() {
        assert_eq!(10, 10.to_proto_id().to_db_id().unwrap());
        assert_eq!(
            10000000000000,
            (10000000000000 as i64).to_proto_id().to_db_id().unwrap()
        );
    }
}

pub fn report_error<E: 'static>(err: E)
where
    E: std::error::Error,
    E: Send + Sync,
{
    let mut stack = String::from("\n");
    if let Some(cause) = err.source() {
        for (i, e) in std::iter::successors(Some(cause), |e| e.source()).enumerate() {
            stack.push_str(&format!("   {}: {}\n", i, e));
        }
    }
    log::error!("[ERROR] {}\nCaused by: {}", err, stack);
}

pub fn env_var(name: &str) -> Option<String> {
    env::var(name).ok().filter(|s| !s.is_empty())
}

pub fn init_crypto() {
    rustls::crypto::ring::default_provider()
        .install_default()
        .expect("Failed to install rustls crypto provider");
}

/// Designed to be called from the main function of a service.
pub fn init_service_logging() {
    env_logger::builder()
        .target(env_logger::Target::Stdout)
        .filter_level(log::LevelFilter::Info)
        .parse_env("RUST_LOG")
        .init();
}

/// Designed to be called from the main function of a bin command.
/// Writes to STDOUT without timestamps.
pub fn init_bin_logging() {
    env_logger::builder()
        .target(env_logger::Target::Stdout)
        .filter_level(log::LevelFilter::Info)
        .format_level(false)
        .format_target(false)
        .format_module_path(false)
        .format_indent(None)
        .format_timestamp(None)
        .parse_env("RUST_LOG")
        .init();
}
