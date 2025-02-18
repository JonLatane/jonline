extern crate async_std;
extern crate async_tls;
extern crate futures_lite;
extern crate reqwest;
extern crate rustls;

use jonline::{init_crypto, init_service_logging};
use serde::{Deserialize, Serialize};

use async_std::io;
use async_std::task;
use std::collections::HashMap;
use std::env;
use std::fs;
use std::io::prelude::*;
use std::thread::sleep;
use std::time::{Duration, Instant};
use std::vec::*;
use structopt::StructOpt;
use tokio;

#[derive(StructOpt)]
struct Options {}

// Jonline Balancer of Loads (JBL) mostly just generates an NGINX configuration
// from some environment variables and Kubernetes secrets, puts them in this file,
// and then starts NGINX (in the foreground) with that configuration.
const NGINX_CONF: &str = "nginx.conf.jbl";

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_crypto();
    init_service_logging();
    let options = Options::from_args();
    let pwd = env::current_dir()
        .expect("PWD must be set")
        .display()
        .to_string();
    let config = setup_nginx_config(&options).await?;

    log::info!(
        "Starting JBL...
         ┏┳ ┳┓ ┓ 
          ┃ ┣┫ ┃ 
         ┗┛ ┻┛ ┗┛
(Jonline Balancer of Loads)
A Rust load balancer for Jonline servers deployed on Kubernetes
"
    );

    log::info!("Finalized config: {:?}", config);

    if config.servers.len() == 0 {
        log::warn!("No servers found in config, starting a no-op loop...");
        task::block_on(async {
            let interval = Duration::from_secs(5);
            let mut next_time = Instant::now() + interval;
            loop {
                sleep(next_time - Instant::now());
                next_time += interval;
            }

            // Ok(())
        });
        return Ok(());
    } else {
        log::info!("NGINX config:\n{}\n", fs::read_to_string(NGINX_CONF)?);
        log::info!("Starting NGINX...");
        let mut nginx = match std::process::Command::new("nginx")
            .args(&[
                "-c",
                NGINX_CONF,
                "-p",
                &pwd,
                "-g",
                "daemon off; error_log /dev/stdout info;",
            ])
            .spawn()
        {
            Ok(process) => process,
            Err(err) => panic!("Nginx crashed: {}", err),
        };

        nginx.wait().expect("Nginx crashed");
    }

    Ok(())
}

// A reference to a K8s namespace containing a `jonline` instance (we will use K8s DNS to route the request)
#[derive(Clone, Debug, Serialize, Deserialize)]
struct Server {
    host: String,
    namespace: String,
}

#[derive(Clone, Debug)]
struct JonlineServerConfig {
    servers: Vec<Server>,
    // rustls_config: ServerConfig,
}
#[derive(Clone, Debug, Serialize, Deserialize)]
struct KubernetesSecrets {
    kind: String,
    #[serde(alias = "apiVersion")]
    api_version: String,
    items: Vec<KubernetesSecretItem>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct KubernetesSecretItem {
    metadata: KubernetesSecretMetadata,
    data: HashMap<String, String>,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
struct KubernetesSecretMetadata {
    name: String,
    namespace: String,
}

/// Load the Jonline server configuration
async fn setup_nginx_config(_options: &Options) -> io::Result<JonlineServerConfig> {
    // let certs = load_certs(&options.cert)?;
    // debug_assert_eq!(1, certs.len());
    // let key = load_key(&options.key)?;

    let env_servers = env::var("SERVERS")
        .expect("SERVERS must be set, JSON of the format [{\"host\": \"\", \"namespace\": \"\"}]");
    let env_no_certs = env::var("NO_CERTS").unwrap_or("false".to_string());
    // TODO:
    log::info!("SERVERS={:?}", env_servers);
    let servers: Vec<Server> = serde_json::from_str(&env_servers)
        .expect(format!("Invalid SERVERS JSON: {}", env_servers).as_str());
    let no_certs = env_no_certs == "true";
    log::info!("Parsed servers: {:?}", &servers);

    // Source: https://stackoverflow.com/questions/73418121/how-allow-pod-from-default-namespace-read-secret-from-other-namespace/73419051#73419051
    // curl -sSk -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"       https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/demo-namespace/secrets

    let k8s_server_host = env::var("KUBERNETES_SERVICE_HOST")
        .unwrap_or("kubernetes.default.svc.cluster.local".to_string());
    let k8s_server_port = env::var("KUBERNETES_PORT_443_TCP_PORT").unwrap_or("443".to_string());
    let k8s_token = fs::read_to_string("/run/secrets/kubernetes.io/serviceaccount/token")
        .unwrap_or("fake-bearer-token".to_string());

    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert(
        "Authorization",
        reqwest::header::HeaderValue::from_str(&format!("Bearer {}", k8s_token)).map_err(|e| {
            log::error!("Failed to set Authorization header: {:?}", e);
            io::Error::new(
                io::ErrorKind::InvalidInput,
                format!("Failed to set Authorization header: {:?}", e),
            )
        })?,
    );

    let client = reqwest::Client::builder()
        .default_headers(headers)
        .danger_accept_invalid_certs(true)
        .build()
        .map_err(|e| {
            log::error!("Failed to build reqwest client: {:?}", e);
            io::Error::new(
                io::ErrorKind::InvalidInput,
                format!("Failed to build reqwest client: {:?}", e),
            )
        })?;

    fs::write(NGINX_CONF, "events {}")?;
    append_to_conf(
        "
http {
    access_log /dev/stdout;",
    )?;
    for server in &servers {
        let host = &server.host;
        let namespace = &server.namespace;

        if no_certs {
            log::info!("Skipping fetching certs for server {host} in namespace {namespace}...");

            append_to_conf(&format!(
                "
    server  {{
        listen 80;
        server_name {host};
        location  / {{
            proxy_pass  https://{host}:80/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }}
    }}
"
            ))?;
        } else {
            log::info!("Fetching certs for server {host} in namespace {namespace}...");
            let secrets_url = format!(
                "https://{}:{}/api/v1/namespaces/{}/secrets",
                k8s_server_host, k8s_server_port, &server.namespace
            );

            // THE LOG BELOW SHOULD DEFINITELY NOT RUN IN REAL PRODUCTION ENVIRIONMENTS (but is needed to test security internally)
            // log::info!("Secrets URL: {:?}", secrets_url);
            // log::info!("K8s Secrets Token: {:?}", k8s_token);

            let secrets = client
                .get(secrets_url)
                .send()
                .await
                .map_err(|e| {
                    log::error!("Failed to fetch secrets: {:?}", e);
                    io::Error::new(
                        io::ErrorKind::InvalidInput,
                        format!("Failed to fetch secrets: {:?}", e),
                    )
                })?
                .text()
                .await
                .map_err(|e| {
                    log::error!("Failed to read secrets: {:?}", e);
                    io::Error::new(
                        io::ErrorKind::InvalidInput,
                        format!("Failed to read secrets: {:?}", e),
                    )
                })?;
            // log::debug!("Secrets response for server {:?}: {:?}", server, secrets);

            let parsed_secrets =
                serde_json::from_str::<KubernetesSecrets>(&secrets).map_err(|e| {
                    log::error!("Failed to parse secrets: {:?}", e);
                    io::Error::new(
                        io::ErrorKind::InvalidInput,
                        format!("Failed to parse secrets: {:?}", e),
                    )
                })?;

            let tls_secrets = parsed_secrets
                .items
                .iter()
                .filter(|item| item.metadata.name == "jonline-generated-tls")
                .next()
                .ok_or_else(|| {
                    log::error!("Failed to find tls secret for server: {:?}", server);
                    io::Error::new(
                        io::ErrorKind::InvalidInput,
                        format!("Failed to find tls secret for server: {:?}", server),
                    )
                })?;

            log::info!(
                "Parsed TLS secrets for server {:?}: {:?}",
                server,
                tls_secrets
            );

            let cert = tls_secrets.data.get("tls.crt").ok_or_else(|| {
                log::error!("Failed to find tls.crt for server: {:?}", server);
                io::Error::new(
                    io::ErrorKind::InvalidInput,
                    format!("Failed to find tls.crt for server: {:?}", server),
                )
            })?;

            let key = tls_secrets.data.get("tls.key").ok_or_else(|| {
                log::error!("Failed to find tls.key for server: {:?}", server);
                io::Error::new(
                    io::ErrorKind::InvalidInput,
                    format!("Failed to find tls.key for server: {:?}", server),
                )
            })?;

            let cert_file = &format!("{host}.crt.jbl");
            fs::write(cert_file, cert)?;
            let key_file = &format!("{host}.key.jbl");
            fs::write(key_file, key)?;

            log::info!(
                "Wrote cert and key for server {host} in namespace {namespace} to files {cert_file} and {key_file}...",
                host = host,
                namespace = namespace,
                cert_file = cert_file,
                key_file = key_file
            );
            log::info!("Cert file contents: \n{:?}", fs::read_to_string(cert_file)?);

            append_to_conf(&format!(
                "
    server  {{
        listen 443 ssl;
        server_name {host};
        ssl_certificate {cert_file};
        ssl_certificate_key {key_file};
        # include /etc/letsencrypt/options-ssl-nginx.conf;
        location  / {{
            proxy_pass  https://{host}:80/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }}
    }}
"
            ))?;
        }
    }

    append_to_conf(
        "
}
    ",
    )?;

    Ok(JonlineServerConfig { servers })
}

fn append_to_conf(content: &str) -> io::Result<()> {
    let mut file = fs::OpenOptions::new()
        .write(true)
        .append(true)
        .open(NGINX_CONF)
        .unwrap();
    let appended_value = match content.chars().next() {
        Some('\n') => content.to_string(),
        _ => format!("\n{}", content),
    };

    writeln!(file, "{}", appended_value)
}
