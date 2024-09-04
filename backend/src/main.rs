#[macro_use]
extern crate diesel;
extern crate async_compression;
extern crate bcrypt;
extern crate bs58;
extern crate diesel_migrations;
extern crate dotenv;
extern crate env_logger;
extern crate futures;
extern crate itertools;
extern crate log;
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
extern crate uuid;
#[macro_use]
extern crate lazy_static;
extern crate awscreds;
// extern crate awsregion;
extern crate bytes;
extern crate ico;
extern crate percent_encoding;
extern crate s3;
extern crate tempfile;
extern crate tokio_stream;
extern crate rand;

pub mod minio_connection;
pub mod db_connection;
pub mod schema;
pub mod models;
pub mod auth;
pub mod protos;
pub mod marshaling;
pub mod logic;
pub mod rpcs;
pub mod jonline_service;
pub mod web;
pub mod servers;

use ::jonline::{env_var, init_crypto, init_service_logging, report_error};
use diesel::*;
use futures::future::join_all;
use marshaling::ToProtoServerConfiguration;
use servers::{start_rocket_secure, start_rocket_unsecured, start_tonic_server};
use std::sync::Arc;
use tokio::task::JoinHandle;

#[rocket::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_crypto();
    init_service_logging();
    db_connection::migrate_database();

    log::info!("Starting Jonline...
┏┳ ┏┓ ┳┓ ┓  ┳ ┳┓ ┏┓
 ┃ ┃┃ ┃┃ ┃  ┃ ┃┃ ┣ 
┗┛ ┗┛ ┛┗ ┗┛ ┻ ┛┗ ┗┛
 (Jonline Server)
A Rust HTTP (80/443/8000) and gRPC (27707) server for Jonline services
");

    let pool = Arc::new(db_connection::establish_pool());
    let bucket = Arc::new(
        *minio_connection::get_and_test_bucket()
            .await
            .expect("Failed to connect to MinIO"),
    );

    let tempdir = Arc::new(tempfile::tempdir().map_err(|e| {
        log::error!("Failed to create tempdir: {:?}", e);
        e
    })?);

    // Ideally, we should be able to restart servers and switch between HTTPS redirects.
    let mut conn = pool
        .get()
        .expect("Failed to get connection trying to load server configuration");
    let mut server_configuration_model: models::ServerConfiguration =
        rpcs::get_server_configuration_model(&mut conn)
            .or_else(|_| {
                log::warn!("Failed to load server configuration, regenerating...");
                rpcs::create_default_server_configuration(&mut conn)
            })
            .expect("Failed to load or regenerate server configuration");
    let server_configuration: protos::ServerConfiguration = server_configuration_model.to_proto();

    let external_cdn_config = server_configuration.external_cdn_config;
    let cdn_grpc = match external_cdn_config {
        None => {
            log::info!("No external CDN configuration found.");
            false
        }
        Some(ref external_cdn_config) => {
            log::info!(
                "Using external CDN configuration: {:?}",
                &external_cdn_config
            );
            external_cdn_config.cdn_grpc
        }
    };

    let tonic_port: u16 = if cdn_grpc {
        log::info!("Using CDN for gRPC communication. Server will *disable this setting* and terminate if secure gRPC is not properly configured.");
        443
        // 27707
    } else {
        27707
    };

    let tls_configuration_successful =
        start_tonic_server(pool.clone(), bucket.clone(), tonic_port)?;

    if cdn_grpc {
        if !tls_configuration_successful {
            log::error!("Secure gRPC configuration failed. Cannot use CDN for gRPC communication. Reverting server configuration and terminating server.");
            let mut external_cdn_config = external_cdn_config.unwrap();
            external_cdn_config.cdn_grpc = false;
            server_configuration_model.external_cdn_config =
                serde_json::to_value(external_cdn_config).ok();
            // server_configuration.external_cdn_config = Some(external_cdn_config);

            diesel::update(schema::server_configurations::table)
                .set(&server_configuration_model)
                .execute(&mut conn)
                .expect("Failed to update server configuration. Bootloops likely.");

            return Ok(());
        }
        log::info!("Secure gRPC configuration successful. Starting only insecure HTTP servers...");
    }

    let mut rocket_handles: Vec<JoinHandle<()>> = vec![];

    let launch_http_as_redirect =
        !cdn_grpc && external_cdn_config.is_none() && tls_configuration_successful;

    log::info!(
        "Insecure HTTP port 80 server is in {} mode.",
        if launch_http_as_redirect {
            "redirect-only"
        } else {
            "standard files and media"
        }
    );

    rocket_handles.push(start_rocket_secure(
        pool.clone(),
        bucket.clone(),
        tempdir.clone(),
    ));
    rocket_handles.push(start_rocket_unsecured(
        80,
        pool.clone(),
        bucket.clone(),
        tempdir.clone(),
        launch_http_as_redirect,
    ));
    rocket_handles.push(start_rocket_unsecured(
        8000,
        pool.clone(),
        bucket.clone(),
        tempdir.clone(),
        false,
    ));

    join_all::<_>(rocket_handles).await;

    Ok(())
}
