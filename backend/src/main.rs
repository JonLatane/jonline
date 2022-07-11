#[macro_use]
extern crate diesel;
extern crate dotenv;
#[macro_use]
extern crate diesel_migrations;
extern crate bcrypt;
extern crate bs58;
extern crate ring;

use std::env;

pub mod db_connection;
pub mod models;
pub mod protos;
pub mod auth;
pub mod rpcs;
pub mod schema;
pub mod jonline;

use crate::jonline::JonLineImpl;
use protos::jonline_server::JonlineServer;

const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("greeter_descriptor");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    db_connection::migrate_database();

    let addr = "[::1]:50051".parse().unwrap();
    let jonline = JonLineImpl {
        pool: db_connection::establish_pool(),
    };

    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()
        .unwrap();

    println!("Jonline server listening on {}", addr);

    tonic::transport::Server::builder()
        .add_service(JonlineServer::new(jonline))
        .add_service(reflection_service)
        .serve(addr)
        .await?;

    Ok(())
}
