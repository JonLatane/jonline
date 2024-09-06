use std::{env, sync::Arc};

use crate::jonline_service::JonlineService;
use crate::{db_connection::PgPool, env_var};

use crate::report_error;

use crate::protos::jonline_server::JonlineServer;

use ::log::{info, warn};
use std::net::SocketAddr;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};
use tonic_web::GrpcWebLayer;
use tower_http::cors::CorsLayer;

const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("greeter_descriptor");

pub fn start_tonic_server(
    pool: Arc<PgPool>,
    bucket: Arc<s3::Bucket>,
    port: u16,
) -> Result<bool, Box<dyn std::error::Error>> {
    let jonline = JonlineService { pool, bucket };

    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build_v1()
        .unwrap();

    let (tonic_server, secure_mode) = match get_tls_config() {
        Some(tls) => {
            info!("Configuring TLS...");
            match Server::builder().tls_config(tls) {
                Ok(server) => {
                    info!("TLS successfully configured.");
                    (server, true)
                }
                Err(details) => {
                    info!("Error configuring TLS. Connections are not secure.");
                    report_error(details);
                    (Server::builder(), false)
                }
            }
        }
        _ => {
            warn!("No TLS keys available. Connections are not secure.");
            (Server::builder(), false)
        }
    };

    let tonic_router = tonic_server
        .accept_http1(true)
        .layer(CorsLayer::permissive())
        .layer(GrpcWebLayer::new())
        // .layer(CorsLayer::permissive())
        .add_service(JonlineServer::new(jonline))
        .add_service(reflection_service);

    tokio::spawn(async move {
        let tonic_addr = SocketAddr::from(([0, 0, 0, 0], port));
        info!("Starting Tonic server on {}", tonic_addr);
        match tonic_router.serve(tonic_addr).await {
            Ok(_) => panic!("Tonic server stopped on {}", tonic_addr),
            Err(e) => {
                ::log::warn!("Unable to start Tonic server on port {}", port);
                report_error(e);
            }
        };
        ()
    });

    Ok(secure_mode)
}

fn get_tls_config() -> Option<ServerTlsConfig> {
    let cert = env_var("TLS_CERT");
    let key = env_var("TLS_KEY");
    let ca_cert = env_var("CA_CERT");

    match (cert, key, ca_cert) {
        (Some(cert), Some(key), Some(ca_cert)) => {
            info!("Configuring TLS with custom CA...");
            Some(
                ServerTlsConfig::new()
                    .identity(Identity::from_pem(cert, key))
                    .client_ca_root(Certificate::from_pem(ca_cert)),
            )
        }
        (Some(cert), Some(key), None) => {
            info!("Configuring TLS with official CAs...");
            Some(ServerTlsConfig::new().identity(Identity::from_pem(cert, key)))
        }
        _ => None,
    }
}
