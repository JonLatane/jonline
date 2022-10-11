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
#[macro_use]
extern crate rocket;
extern crate futures;
extern crate serde;
extern crate serde_json;
extern crate rocket_async_compression;


use std::{
    env, fs,
    path::{Path, PathBuf},
};

pub mod auth;
pub mod conversions;
pub mod db_connection;
pub mod jonline;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;
pub mod logic;

use crate::jonline::JonLineImpl;
use ::jonline::{db_connection::PgPool, env_var, report_error};
use futures::future::join_all;
use protos::jonline_server::JonlineServer;
use rocket::fs::NamedFile;
use std::net::SocketAddr;
use tonic::transport::{Certificate, Identity, Server, ServerTlsConfig};
use rocket_async_compression::Compression;

const FILE_DESCRIPTOR_SET: &[u8] = tonic::include_file_descriptor_set!("greeter_descriptor");

#[rocket::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    db_connection::migrate_database();
    let pool = db_connection::establish_pool();

    tokio::spawn(async {
        let tonic_addr = SocketAddr::from(([0, 0, 0, 0], 27707));
        let tonic_router = create_tonic_router(pool);
        match tonic_router.serve(tonic_addr).await {
            Ok(_) => println!("Tonic server started on {}", tonic_addr),
            Err(e) => {
                println!("Unable to start Rocket server on port 8000");
                report_error(e);
            }
        };
        ()
    });

    let rocket_unsecure_8000_server = rocket::tokio::spawn(async {
        match create_rocket_unsecured(8000).launch().await {
            Ok(_) => (),
            Err(e) => {
                println!("Unable to start Rocket server on port 8000");
                report_error(e);
            }
        };
        ()
    });
    let rocket_unsecure_80_server = rocket::tokio::spawn(async {
        match create_rocket_unsecured(80).launch().await {
            Ok(_) => (),
            Err(e) => {
                println!("Unable to start Rocket server on port 80");
                report_error(e);
            }
        };
        ()
    });
    let rocket_secure_server = rocket::tokio::spawn(async {
        match create_rocket_secure() {
            None => (),
            Some(rocket) => match rocket.launch().await {
                Ok(_) => (),
                Err(e) => {
                    println!("Unable to start secure Rocket server on port 443");
                    report_error(e);
                }
            },
        };
        ()
    });

    join_all::<_>([
        // tonic_server,
        rocket_unsecure_8000_server,
        rocket_unsecure_80_server,
        rocket_secure_server,
    ])
    .await;

    Ok(())
}

fn create_rocket_secure() -> Option<rocket::Rocket<rocket::Build>> {
    let cert = env_var("TLS_CERT");
    let key = env_var("TLS_KEY");

    match (cert, key) {
        (Some(cert), Some(key)) => {
            println!("Configuring Rocket TLS...");

            fs::write(".tls.crt", cert).expect("Unable to write TLS certificate");
            fs::write(".tls.key", key).expect("Unable to write TLS key");
            let figment = rocket::Config::figment()
                .merge(("port", 443))
                .merge(("address", "0.0.0.0"))
                .merge(("tls.certs", ".tls.crt"))
                .merge(("tls.key", ".tls.key"));
            Some(create_rocket(figment))
        }
        _ => None,
    }
}

fn create_rocket_unsecured(port: i32) -> rocket::Rocket<rocket::Build> {
    let figment = rocket::Config::figment()
    .merge(("port", port))
    .merge(("address", "0.0.0.0"));
    create_rocket(figment)
}

fn create_rocket<T: rocket::figment::Provider>(figment: T) -> rocket::Rocket<rocket::Build> {
    let server = rocket::custom(figment).mount("/", routes![index, file]);
    if cfg!(debug_assertions) {
        server
    } else {
        server.attach(Compression::fairing())
    }
}

#[get("/<file..>")]
pub async fn file(file: PathBuf) -> std::io::Result<NamedFile> {
    match NamedFile::open(Path::new("opt/web/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../frontend/build/web/").join(file)).await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    }
}
#[get("/")]
pub async fn index() -> std::io::Result<NamedFile> {
    match NamedFile::open("opt/web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontend/build/web/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    }
}
// #[get("/<path..>")]
// fn redirect(file: PathBuf) -> &'static str {
//     "Hey, you're here."
// }


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
