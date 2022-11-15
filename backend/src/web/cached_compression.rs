use lazy_static::lazy_static;
use rocket::fairing::{Fairing, Info, Kind};
use rocket::{Request, Response};
use tokio::io::AsyncReadExt;
use std::collections::HashMap;
use std::io::Cursor;
use std::sync::Mutex;

lazy_static! {
  static ref CACHED_FILES: Mutex<HashMap<(String, bool, bool), (Vec<u8>, String)>> = {
      let m = HashMap::new();
      // m.insert(0, "foo");
      // m.insert(1, "bar");
      // m.insert(2, "baz");
      Mutex::new(m)
  };    
}

pub struct CachedCompression(());

impl CachedCompression {
    pub fn fairing() -> CachedCompression {
      CachedCompression(())
    }
}

#[rocket::async_trait]
impl Fairing for CachedCompression {
    fn info(&self) -> Info {
        Info {
            name: "Cached response compression",
            kind: Kind::Response,
        }
    }

    async fn on_response<'r>(&self, request: &'r Request<'_>, response: &mut Response<'r>) {
        let path = request.uri().path().to_string();
        let cache_compressed_respones = path.ends_with(".otf") || path.ends_with("main.dart.js");
        let (accepts_gzip, accepts_br) = request
            .headers()
            .get("Accept-Encoding")
            .flat_map(|accept| accept.split(','))
            .map(|accept| accept.trim())
            .fold((false, false), |(accepts_gzip, accepts_br), encoding| {
                (
                    accepts_gzip || encoding == "gzip",
                    accepts_br || encoding == "br",
                )
            });

        if cache_compressed_respones {
            let guard = CACHED_FILES.lock().unwrap();
            if let Some((cached_body, header)) = guard.get(&(path.clone(), accepts_gzip, accepts_br)) {
                response.set_header(rocket::http::Header::new(
                    "content-encoding",
                    header.clone(),
                ));
                let body = cached_body.clone();
                response.set_sized_body(body.len(), Cursor::new(body));
                return;
            } else {
                drop(guard);
            }
        }

        rocket_async_compression::Compression::fairing().on_response(request, response).await;

        if !cache_compressed_respones {
            return;
        }

        let mut compressed_body: Vec<u8> = vec![];
        match response.body_mut().read_to_end(&mut compressed_body).await {
            Err(_) => return,
            _ => ()
        }
        response.set_sized_body(compressed_body.len(), Cursor::new(compressed_body.clone()));
        let header = response.headers().get_one("content-encoding").unwrap().to_string();
        let mut guard = CACHED_FILES.lock().unwrap();
        guard.insert((path, accepts_gzip, accepts_br), (compressed_body, header));
        drop(guard);
    }
}
