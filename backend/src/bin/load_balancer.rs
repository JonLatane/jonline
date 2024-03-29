extern crate async_std;
extern crate async_tls;
extern crate futures_lite;
extern crate rustls;
extern crate reqwest;

use jonline::init_bin_logging;

use async_std::io;
use async_std::net::{TcpListener, TcpStream};
use async_std::stream::StreamExt;
use async_std::task;
use async_tls::TlsAcceptor;
use futures_lite::io::AsyncWriteExt;
use log::info;
use rustls::server::ResolvesServerCert;
use rustls::{Certificate, PrivateKey, ServerConfig};
use rustls_pemfile::{certs, read_one, Item};

use std::env;
use std::fs::File;
use std::io::BufReader;
use std::net::ToSocketAddrs;
use std::path::{Path, PathBuf};
use std::sync::Arc;
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

/// Load the passed certificates file
fn load_certs(path: &Path) -> io::Result<Vec<Certificate>> {
    Ok(certs(&mut BufReader::new(File::open(path)?))
        .map_err(|_| io::Error::new(io::ErrorKind::InvalidInput, "invalid cert"))?
        .into_iter()
        .map(Certificate)
        .collect())
}

/// Load the passed keys file
fn load_key(path: &Path) -> io::Result<PrivateKey> {
    match read_one(&mut BufReader::new(File::open(path)?)) {
        Ok(Some(Item::RSAKey(data) | Item::PKCS8Key(data))) => Ok(PrivateKey(data)),
        Ok(_) => Err(io::Error::new(
            io::ErrorKind::InvalidInput,
            format!("invalid key in {}", path.display()),
        )),
        Err(e) => Err(io::Error::new(io::ErrorKind::InvalidInput, e)),
    }
}

// A reference to a K8s namespace containing a `jonline` instance (we will use K8s DNS to route the request)
#[derive(serde::Serialize, serde::Deserialize)]
struct Server {
    host: String,
    namespace: String,
}

struct ServerResolver {
    servers: Vec<Server>,
}

impl ResolvesServerCert for ServerResolver {
    fn resolve(
        &self,
        client_hello: rustls::server::ClientHello,
    ) -> Option<Arc<rustls::sign::CertifiedKey>> {
        info!("Resolving client hello: {:?}", client_hello.server_name());
        todo!()
    }
}

/// Configure the server using rusttls
/// See https://docs.rs/rustls/0.16.0/rustls/struct.ServerConfig.html for details
///
/// A TLS server needs a certificate and a fitting private key
fn load_config(options: &Options) -> io::Result<ServerConfig> {
    // let certs = load_certs(&options.cert)?;
    // debug_assert_eq!(1, certs.len());
    // let key = load_key(&options.key)?;

    let env_servers = env::var("SERVERS").expect("SERVERS must be set, JSON of the format [");
    // TODO:
    let servers: ServerResolver = ServerResolver { servers: vec![] };
    let server_arc = Arc::new(servers);
    // we don't use client authentication
    let config = ServerConfig::builder()
        .with_safe_defaults()
        .with_no_client_auth()
        .with_cert_resolver(server_arc);
    // set this server to use one cert together with the loaded private key
    // .with_single_cert(certs, key)

    // .map_err(|err| io::Error::new(io::ErrorKind::InvalidInput, err))?;

    Ok(config)
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

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    init_bin_logging();
    let options = Options::from_args();

    log::info!("JBL: Jonline Balancer of Loads");
    log::info!("A Rust Load Balancer for Jonline Kubernetes services");
    log::info!("JBL: Jonline Balancer of Loads");
    let addr = options
        .addr
        .to_socket_addrs()?
        .next()
        .ok_or_else(|| io::Error::from(io::ErrorKind::AddrNotAvailable))?;

    let config = load_config(&options)?;

    // We create one TLSAcceptor around a shared configuration.
    // Cloning the acceptor will not clone the configuration.
    let acceptor = TlsAcceptor::from(Arc::new(config));

    load_secrets().await;

    // We start a classic TCP server, passing all connections to the
    // handle_connection async function
    task::block_on(async {
        let listener = TcpListener::bind(&addr).await?;
        let mut incoming = listener.incoming();

        while let Some(stream) = incoming.next().await {
            // We use one acceptor per connection, so
            // we need to clone the current one.
            let acceptor = acceptor.clone();
            let mut stream = stream?;

            // TODO: scoped tasks?
            task::spawn(async move {
                let res = handle_connection(&acceptor, &mut stream).await;
                match res {
                    Ok(_) => {}
                    Err(err) => {
                        eprintln!("{:?}", err);
                    }
                };
            });
        }

        Ok(())
    })
}

// shell script version of this:
//  curl -sSk -H "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)"       https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/demo-namespace/secrets
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
