#[macro_use]
extern crate diesel;
extern crate dotenv;
#[macro_use]
extern crate diesel_migrations;
extern crate bcrypt;
extern crate bs58;
extern crate ring;
extern crate prost_types;

use std::env;

pub mod auth;
pub mod db_connection;
pub mod jonline;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;

use crate::jonline::JonLineImpl;
use ::jonline::report_error;
use protos::jonline_server::JonlineServer;
use std::net::SocketAddr;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};

const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("greeter_descriptor");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    db_connection::migrate_database();

    let addr = SocketAddr::from(([0, 0, 0, 0], 27707));

    let jonline = JonLineImpl {
        pool: db_connection::establish_pool(),
    };

    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()
        .unwrap();

    println!("Jonline is starting on {}...", addr);

    let server = create_server()
        .add_service(JonlineServer::new(jonline))
        .add_service(reflection_service)
        .serve(addr);

    server.await?;
    Ok(())
}

fn create_server() -> Server {
    match get_tls_config() {
        Some(tls) => {
            println!("Configuring TLS...");
            match Server::builder().tls_config(tls) {
                Ok(server) => {
                    println!("TLS successfully configured.");
                    server
                },
                Err(details) => {
                    println!("Failed to configure TLS. Connections are not secure. Source error: {}", details);
                    report_error(details);
                    Server::builder()
                }
            }
        }
        _ => {
            println!("No TLS keys available. Connections are not secure.");
            Server::builder()
        }
    }
}

fn get_tls_config() -> Option<ServerTlsConfig> {
    println!("TLS Debug: TLS_KEY = {}", env::var("TLS_KEY").unwrap_or("".to_owned()));
    println!("TLS Debug: TLS_CERT = {}", env::var("TLS_CERT").unwrap_or("".to_owned()));
    println!("TLS Debug: CA_CERT = {}", env::var("CA_CERT").unwrap_or("".to_owned()));
    let cert = env::var("TLS_KEY").ok().filter(|s| !s.is_empty());
    let key = env::var("TLS_CERT").ok().filter(|s| !s.is_empty());
    let ca_cert = env::var("CA_CERT").ok().filter(|s| !s.is_empty());

    match (cert, key, ca_cert) {
        (Some(cert), Some(key), Some(ca_cert)) => Some(
            ServerTlsConfig::new()
                .identity(Identity::from_pem(cert.as_bytes(), key.as_bytes()))
                .client_ca_root(Certificate::from_pem(ca_cert.as_bytes())),
        ),
        _ => None,
    }
}
