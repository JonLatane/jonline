#[macro_use]
extern crate diesel;
extern crate dotenv;
#[macro_use]
extern crate diesel_migrations;
extern crate bcrypt;
extern crate bs58;
extern crate prost_types;
extern crate regex;
extern crate ring;
extern crate tonic_web;

use std::env;

pub mod auth;
pub mod conversions;
pub mod db_connection;
pub mod jonline;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;

use crate::jonline::JonLineImpl;
use ::jonline::{db_connection::PgPool, env_var, report_error};
use protos::jonline_server::JonlineServer;
use std::net::SocketAddr;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};

const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("greeter_descriptor");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    db_connection::migrate_database();
    let pool = db_connection::establish_pool();
    let tonic_addr = SocketAddr::from(([0, 0, 0, 0], 27707));
    let tonic_router = create_tonic_router(pool);
    let tonic_result = tonic_router.serve(tonic_addr);
    tonic_result.await?;
    Ok(())
}

fn create_tonic_router(pool: PgPool) -> tonic::transport::server::Router {
    let jonline = JonLineImpl { pool };

    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()
        .unwrap();

    let server = match get_tls_config() {
        Some(tls) => {
            println!("Configuring TLS...");
            match Server::builder().tls_config(tls) {
                Ok(server) => {
                    println!("TLS successfully configured.");
                    server
                }
                Err(details) => {
                    println!("Error configuring TLS. Connections are not secure.");
                    report_error(details);
                    Server::builder()
                }
            }
        }
        _ => {
            println!("No TLS keys available. Connections are not secure.");
            Server::builder()
        }
    };

    server
        .accept_http1(true)
        .add_service(tonic_web::enable(JonlineServer::new(jonline)))
        .add_service(tonic_web::enable(reflection_service))
}

fn get_tls_config() -> Option<ServerTlsConfig> {
    let cert = env_var("TLS_CERT");
    let key = env_var("TLS_KEY");
    let ca_cert = env_var("CA_CERT");
    // println!("TLS Debug: TLS_KEY = {}", debug_format(&key));
    // println!("TLS Debug: TLS_CERT = {}", debug_format(&cert));
    // println!("TLS Debug: CA_CERT = {}", debug_format(&ca_cert));

    match (cert, key, ca_cert) {
        (Some(cert), Some(key), Some(ca_cert)) => {
            println!("Configuring TLS with custom CA...");
            Some(
                ServerTlsConfig::new()
                    .identity(Identity::from_pem(cert, key))
                    .client_ca_root(Certificate::from_pem(ca_cert)),
            )
        }
        (Some(cert), Some(key), None) => {
            println!("Configuring TLS with official CAs...");
            Some(ServerTlsConfig::new().identity(Identity::from_pem(cert, key)))
        }
        _ => None,
    }
}
