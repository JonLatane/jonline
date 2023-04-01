use std::env;

#[macro_use]
extern crate diesel;
extern crate dotenv;
extern crate diesel_migrations;
extern crate bcrypt;
extern crate bs58;
extern crate ring;
extern crate tonic_web;
extern crate futures;
extern crate serde;
extern crate serde_json;
extern crate itertools;
#[macro_use]
extern crate lazy_static;
extern crate log;
extern crate tokio_stream;

pub mod auth;
pub mod jonline;
pub mod models;
pub mod protos;
pub mod rpcs;
pub mod schema;
pub mod marshaling;
pub mod logic;
pub mod web;
pub mod servers;
pub mod db_connection;

#[cfg(test)]
mod tests {
    use crate::marshaling::ToProtoId;
    use crate::marshaling::ToDbId;

    #[test]
    fn id_conversions_work() {
        assert_eq!(10, 10.to_proto_id().to_db_id().unwrap());
    }
}

pub fn report_error<E: 'static>(err: E)
where
    E: std::error::Error,
    E: Send + Sync,
{
    log::error!("[ERROR] {}", err);
    if let Some(cause) = err.source() {
        log::error!("[ERROR] {}", err);
        log::error!("Caused by:");
        for (i, e) in std::iter::successors(Some(cause), |e| e.source()).enumerate() {
            log::error!("   {}: {}", i, e);
        }
    }
}

pub fn env_var(name: &str) -> Option<String> {
    env::var(name)
        .ok()
        .filter(|s| !s.is_empty())
}

// fn debug_format(cert: &Option<String>) -> String {
//     cert.to_owned().unwrap_or("".to_string())
// }

// fn trim_cert(str: &str) -> String {
//     let re1 = Regex::new(r"-----[A-Z ]+-----").unwrap();
//     let re2 = Regex::new(r"\n").unwrap();
//     let re3 = Regex::new(r"^\n").unwrap();
//     let re4 = Regex::new(r"\n$").unwrap();
//     re4.replace_all(
//         &re3.replace_all(&re2.replace_all(&re1.replace_all(&str, ""), ""), ""),
//         "",
//     )
//     .to_string()
// }
