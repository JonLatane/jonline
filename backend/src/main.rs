#[macro_use]
extern crate diesel;
extern crate bcrypt;
extern crate bs58;
extern crate uuid;
extern crate diesel_migrations;
extern crate dotenv;
extern crate env_logger;
extern crate futures;
extern crate itertools;
extern crate log;
extern crate markdown;
extern crate prost_types;
extern crate prost_wkt_types;
extern crate regex;
extern crate ring;
extern crate rocket;
extern crate rocket_async_compression;
extern crate rocket_cache_response;
extern crate serde;
extern crate serde_json;
extern crate tonic_web;
#[macro_use]
extern crate lazy_static;
extern crate awscreds;
extern crate awsregion;
extern crate s3;
extern crate bytes;
extern crate tokio_stream;

pub mod auth;
pub mod db_connection;
pub mod jonline;
pub mod logic;
pub mod marshaling;
pub mod minio_connection;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;
pub mod servers;
pub mod web;

use ::jonline::{env_var, init_service_logging, report_error};
use futures::future::join_all;
use servers::{start_rocket_secure, start_rocket_unsecured, start_tonic_server};
use std::sync::Arc;

#[rocket::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_service_logging();
    db_connection::migrate_database();

    let pool1 = Arc::new(db_connection::establish_pool());
    let pool2 = pool1.clone();
    let pool3 = pool1.clone();
    let pool4 = pool1.clone();

    let bucket = minio_connection::get_and_test_bucket().await.map_err(|e| {
        log::error!("Failed to connect to MinIO: {:?}", e);
        // let _fake_bucket = s3::Bucket::new("fake", awsregion::Region::AfSouth1, awscreds::Credentials::default().unwrap()).unwrap();
        // _fake_bucket
        //TODO map to this error and end the map_err with "?".
        std::io::Error::new(std::io::ErrorKind::Other, "Failed to connect to MinIO")
    })?;

    let bucket1 = Arc::new(bucket/*.unwrap_or_else(|b| { b }) */);
    let bucket2 = bucket1.clone();
    let bucket3 = bucket1.clone();
    let bucket4 = bucket1.clone();

    let secure_mode = start_tonic_server(pool1, bucket1)?;

    let rocket_unsecure_8000 = start_rocket_unsecured(8000, pool2, bucket2, secure_mode);
    let rocket_unsecure_80 = start_rocket_unsecured(80, pool3, bucket3, secure_mode);
    let rocket_secure = start_rocket_secure(pool4, bucket4);

    join_all::<_>([
        // tonic_server,
        rocket_unsecure_8000,
        rocket_unsecure_80,
        rocket_secure,
    ])
    .await;

    Ok(())
}
