use std::{env, sync::Arc};

use crate::db_connection::PgPool;
use crate::jonline::JonLineImpl;

use crate::report_error;

use crate::protos::jonline_server::JonlineServer;
use crate::tls::get_tls_config;

use std::net::SocketAddr;
use tonic::transport::Server;
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("greeter_descriptor");

pub fn start_tonic_server(pool: Arc<PgPool>) -> Result<bool, Box<dyn std::error::Error>> {
    let jonline = JonLineImpl { pool };

    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()
        .unwrap();

    let (tonic_server, secure_mode) = match get_tls_config() {
        Some(tls) => {
            ::log::info!("Configuring TLS...");
            match Server::builder().tls_config(tls) {
                Ok(server) => {
                    ::log::info!("TLS successfully configured.");
                    (server, true)
                }
                Err(details) => {
                    ::log::info!("Error configuring TLS. Connections are not secure.");
                    report_error(details);
                    (Server::builder(), false)
                }
            }
        }
        _ => {
            ::log::warn!("No TLS keys available. Connections are not secure.");
            (Server::builder(), false)
        }
    };

    let tonic_router = tonic_server
        .accept_http1(true)
        .layer(CorsLayer::very_permissive())
        .layer(GrpcWebLayer::new())
        .add_service(JonlineServer::new(jonline))
        .add_service(reflection_service);

    tokio::spawn(async {
        let tonic_addr = SocketAddr::from(([0, 0, 0, 0], 27707));
        match tonic_router.serve(tonic_addr).await {
            Ok(_) => ::log::info!("Tonic server started on {}", tonic_addr),
            Err(e) => {
                ::log::warn!("Unable to start Tonic server on port 27707");
                report_error(e);
            }
        };
        ()
    });

    Ok(secure_mode)
}
