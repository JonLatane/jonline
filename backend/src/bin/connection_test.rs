extern crate jonline;
use std::time::Duration;

use jonline::{protos::jonline_client, *};
use tonic::{transport::*, Request};

const PROTOCOL: &str = "https";
const HOST: &str = "be.jonline.io";
const PORT: i32 = 27707;

#[tokio::main]
async fn main() {
    let protocol = env_var("PROTOCOL").unwrap_or(PROTOCOL.to_string());
    let host = env_var("HOST").unwrap_or(HOST.to_string());
    let port = env_var("PORT").unwrap_or(PORT.to_string());
    let route = format!("{}://{}:{}", protocol, host, port);
    let endpoint = Channel::from_shared(route).expect("Failed to create channel");
    let endpoint = match get_tls_config() {
        Some(tls) => {
            println!("Configuring custom CA_CERT in TLS...");
            match endpoint.tls_config(tls) {
                Ok(endpoint) => endpoint,
                Err(err) => {
                    println!("Error configuring custom CA_CERT in TLS.");
                    report_error(err);
                    return;
                }
            }
        }
        None => endpoint,
    };
    let channel: Channel = endpoint
        .timeout(Duration::from_secs(5))
        .rate_limit(5, Duration::from_secs(1))
        .concurrency_limit(256)
        .connect()
        .await
        .expect("Failed to establish channel");

    let mut client = jonline_client::JonlineClient::new(channel);
    client
        .get_service_version(Request::new(()))
        .await
        .expect("Failed to get service version");

    println!("Connection test complete!");
}

fn get_tls_config() -> Option<ClientTlsConfig> {
    let ca_cert = env_var("CA_CERT");

    match ca_cert {
        Some(ca_cert) => Some(
            ClientTlsConfig::new()
                .ca_certificate(Certificate::from_pem(&ca_cert))
                .domain_name(HOST),
        ),
        _ => None,
    }
}
