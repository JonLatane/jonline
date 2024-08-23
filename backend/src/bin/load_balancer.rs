extern crate async_std;
extern crate async_tls;
extern crate futures_lite;
extern crate reqwest;
extern crate rustls;

use jonline::{init_crypto, init_bin_logging, init_service_logging};

use async_std::io;
use async_std::net::{TcpListener, TcpStream};
use async_std::stream::StreamExt;
use async_std::task;
use async_tls::TlsAcceptor;
use futures_lite::io::AsyncWriteExt;
use log::info;
// use rustls::server::ResolvesServerCert;
// use rustls::{Certificate, PrivateKey, ServerConfig};
// use rustls_pemfile::{certs, read_one, Item};

use http;
use http::{HeaderMap, HeaderValue, Request, Response};
use std::env;
use std::fs;
use std::fs::File;
use std::io::BufReader;
use std::net::ToSocketAddrs;
use std::path::Path;
use std::sync::Arc;
use std::thread::sleep;
use std::time::{Duration, Instant};
use std::vec::*;
use structopt::StructOpt;
use tokio;

#[derive(StructOpt)]
struct Options {
    addr: String,
    // /// cert file
    // #[structopt(short = "c", long = "cert", parse(from_os_str))]
    // cert: PathBuf,

    // /// key file
    // #[structopt(short = "k", long = "key", parse(from_os_str))]
    // key: PathBuf,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_crypto();
    init_service_logging();
    let options = Options::from_args();
    log::info!(
        "Starting JBL...
         ┏┳ ┳┓ ┓ 
          ┃ ┣┫ ┃ 
         ┗┛ ┻┛ ┗┛
(Jonline Balancer of Loads)
A Rust load balancer for Jonline servers deployed on Kubernetes
"
    );
    // log::info!("JBL: Jonline Balancer of Loads");
    let addr = options
        .addr
        .to_socket_addrs()?
        .next()
        .ok_or_else(|| io::Error::from(io::ErrorKind::AddrNotAvailable))?;
    log::info!("Socket address: {:?}", addr);

    let config = load_config(&options).await?;
    log::info!("Finalized config: {:?}", config);

    // We create one TLSAcceptor around a shared configuration.
    // Cloning the acceptor will not clone the configuration.
    // let acceptor = TlsAcceptor::from(Arc::new(config.rustls_config));

    // load_secrets().await;

    // We start a classic TCP server, passing all connections to the
    // handle_connection async function
    task::block_on(async {
        log::info!("Initiating main loop...");
        let interval = Duration::from_secs(5);
        let mut next_time = Instant::now() + interval;
        loop {
            log::info!("Looping...");
            sleep(next_time - Instant::now());
            next_time += interval;
        }

        // let listener = TcpListener::bind(&addr).await?;
        // let mut incoming = listener.incoming();

        // log::info!("Initiating rustls main loop...");
        // while let Some(stream) = incoming.next().await {
        //     // We use one acceptor per connection, so
        //     // we need to clone the current one.
        //     let acceptor = acceptor.clone();
        //     let mut stream = stream?;
        //     log::info!("Accepted a rustls stream...");

        //     // TODO: scoped tasks?
        //     task::spawn(async move {
        //         let res = handle_connection(&acceptor, &mut stream).await;
        //         match res {
        //             Ok(_) => {}
        //             Err(err) => {
        //                 eprintln!("{:?}", err);
        //             }
        //         };
        //     });
        // }

        Ok(())
    })
}

// /// Load the passed certificates file
// fn _load_certs(path: &Path) -> io::Result<Vec<Certificate>> {
//     Ok(certs(&mut BufReader::new(File::open(path)?))
//         .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "invalid cert"))?
//         .into_iter()
//         .map(Certificate)
//         .collect())
// }

// /// Load the passed keys file
// fn _load_key(path: &Path) -> io::Result<PrivateKey> {
//     match read_one(&mut BufReader::new(File::open(path)?)) {
//         Ok(Some(Item::RSAKey(data) | Item::PKCS8Key(data))) => Ok(PrivateKey(data)),
//         Ok(_) => Err(io::Error::new(
//             io::ErrorKind::InvalidInput,
//             format!("invalid key in {}", path.display()),
//         )),
//         Err(e) => Err(io::Error::new(io::ErrorKind::InvalidInput, e)),
//     }
// }

// A reference to a K8s namespace containing a `jonline` instance (we will use K8s DNS to route the request)
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
struct Server {
    host: String,
    namespace: String,
}
// #[derive(Clone)]
// struct ServerResolver {
//     servers: Vec<Server>,
// }

// impl ResolvesServerCert for ServerResolver {
//     fn resolve(
//         &self,
//         client_hello: rustls::server::ClientHello,
//     ) -> Option<Arc<rustls::sign::CertifiedKey>> {
//         info!("Resolving client hello: {:?}", client_hello.server_name());
//         todo!()
//     }
// }

#[derive(Clone, Debug)]
struct JonlineServerConfig {
    servers: Vec<Server>,
    // rustls_config: ServerConfig,
}

/// Load the Jonline server configuration
async fn load_config(options: &Options) -> io::Result<JonlineServerConfig> {
    // let certs = load_certs(&options.cert)?;
    // debug_assert_eq!(1, certs.len());
    // let key = load_key(&options.key)?;

    let env_servers = env::var("SERVERS")
        .expect("SERVERS must be set, JSON of the format [{\"host\": \"\", \"namespace\": \"\"}]");
    // TODO:
    log::info!("SERVERS={:?}", env_servers);
    let servers: Vec<Server> = serde_json::from_str(&env_servers)
        .expect(format!("Invalid SERVERS JSON: {}", env_servers).as_str());
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
        .build()
        .map_err(|e| {
            log::error!("Failed to build reqwest client: {:?}", e);
            io::Error::new(
                io::ErrorKind::InvalidInput,
                format!("Failed to build reqwest client: {:?}", e),
            )
        })?;

    for server in &servers {
        log::info!("Fetching certs for server: {:?}", server);
        let secrets_url = format!(
            "https://{}:{}/api/v1/namespaces/{}/secrets",
            k8s_server_host, k8s_server_port, &server.namespace
        );

        // THE LOG BELOW SHOULD DEFINITELY NOT RUN IN REAL PRODUCTION ENVIRIONMENTS (but is needed to test security internally)
        log::info!("Secrets URL: {:?}", secrets_url);
        log::info!("K8s Secrets Token: {:?}", k8s_token);

        // let secrets = client
        //     .get(secrets_url)
        //     .send()
        //     .await
        //     .map_err(|e| {
        //         log::error!("Failed to fetch secrets: {:?}", e);
        //         io::Error::new(
        //             io::ErrorKind::InvalidInput,
        //             format!("Failed to fetch secrets: {:?}", e),
        //         )
        //     })?
        //     .text()
        //     .await
        //     .map_err(|e| {
        //         log::error!("Failed to read secrets: {:?}", e);
        //         io::Error::new(
        //             io::ErrorKind::InvalidInput,
        //             format!("Failed to read secrets: {:?}", e),
        //         )
        //     })?;
        // let response = http::send(request.body(()).unwrap());
        // log::info!("Secrets response for server {:?}: {:?}", server, secrets);
    }

    // // Configure the server using rustls
    // // See https://docs.rs/rustls/0.16.0/rustls/struct.ServerConfig.html for details
    // //
    // // A TLS server needs a certificate and a fitting private key
    // let server_resolver: ServerResolver = ServerResolver {
    //     servers: servers.clone(),
    // };
    // let server_arc = Arc::new(server_resolver.clone());
    // // we don't use client authentication
    // let rustls_config = ServerConfig::builder()
    //     .with_safe_defaults()
    //     .with_no_client_auth()
    //     .with_cert_resolver(server_arc);
    // // set this server to use one cert together with the loaded private key
    // // .with_single_cert(certs, key)

    // // .map_err(|err| io::Error::new(io::ErrorKind::InvalidInput, err))?;

    Ok(JonlineServerConfig {
        servers,
        // rustls_config,
    })
}

/// The connection handling function.
async fn handle_connection(acceptor: &TlsAcceptor, tcp_stream: &mut TcpStream) -> io::Result<()> {
    let peer_addr = tcp_stream.peer_addr()?;
    println!("Connection from: {}", peer_addr);

    // Calling `acceptor.accept` will start the TLS handshake
    let handshake = acceptor.accept(tcp_stream);
    // The handshake is a future we can await to get an encrypted
    // stream back.
    let mut tls_stream = handshake.await?;

    // Use the stream like any other
    tls_stream
        .write_all(
            &b"HTTP/1.0 200 ok\r\n\
        Connection: close\r\n\
        Content-length: 12\r\n\
        \r\n\
        Hello world!"[..],
        )
        .await?;

    tls_stream.close().await?;

    Ok(())
}

// shell script version of this:
//  curl -sSk -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"       https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/jonline/secrets
async fn load_secrets() {
    log::info!("Loading secrets...");
    let token = std::fs::read_to_string("/run/secrets/kubernetes.io/serviceaccount/token").unwrap();
    let url = format!(
        "https://{}:{}/api/v1/namespaces/{}/secrets",
        std::env::var("KUBERNETES_SERVICE_HOST").unwrap(),
        std::env::var("KUBERNETES_PORT_443_TCP_PORT").unwrap(),
        std::env::var("NAMESPACE").unwrap()
    );
    let resp = reqwest::Client::new()
        .get(&url)
        .header("Authorization", format!("Bearer {}", token))
        .send()
        .await
        .unwrap();
    // println!("{:?}", resp);
    log::info!("Got secrets response: {:?}", resp);
}

// use hudsucker::{
//   async_trait::async_trait,
//   certificate_authority::OpensslAuthority,
//   hyper::{Body, Request, Response},
//   openssl::{hash::MessageDigest, pkey::PKey, x509::X509},
//   tokio_tungstenite::tungstenite::Message,
//   *,
// };
// use std::net::SocketAddr;
// use log::error;

// async fn shutdown_signal() {
//   tokio::signal::ctrl_c()
//       .await
//       .expect("Failed to install CTRL+C signal handler");
// }

// #[derive(Clone)]
// struct LogHandler;

// #[async_trait]
// impl HttpHandler for LogHandler {
//   async fn handle_request(
//       &mut self,
//       _ctx: &HttpContext,
//       req: Request<Body>,
//   ) -> RequestOrResponse {
//       println!("{:?}", req);
//       req.into()
//   }

//   async fn handle_response(&mut self, _ctx: &HttpContext, res: Response<Body>) -> Response<Body> {
//       println!("{:?}", res);
//       res
//   }
// }

// #[async_trait]
// impl WebSocketHandler for LogHandler {
//   async fn handle_message(&mut self, _ctx: &WebSocketContext, msg: Message) -> Option<Message> {
//       println!("{:?}", msg);
//       Some(msg)
//   }
// }

// #[tokio::main]
// async fn main() {
//   // tracing_subscriber::fmt::init();

//   // let private_key_bytes: &[u8] = include_bytes!("../generated_certs/ca.key");
//   // let ca_cert_bytes: &[u8] = include_bytes!("../generated_certs/ca.pem");
//   //include_bytes!("ca/hudsucker.cer");
//   // let private_key =
//   //     PKey::private_key_from_pem(private_key_bytes).expect("Failed to parse private key");
//   // let ca_cert = X509::from_pem(ca_cert_bytes).expect("Failed to parse CA certificate");

//   // let ca = OpensslAuthority::new(private_key, ca_cert, MessageDigest::sha256(), 1_000);

//   let proxy = Proxy::builder()
//       .with_addr(SocketAddr::from(([127, 0, 0, 1], 3000)))
//       .with_rustls_client()
//       .with_ca(OpensslAuthority::default())
//       // .cer
//       // .with_ca(ca)
//       .with_http_handler(LogHandler)
//       .build();

//   if let Err(e) = proxy.start(shutdown_signal()).await {
//       error!("{}", e);
//   }
// }
