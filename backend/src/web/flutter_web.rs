use rocket::{fs::*, http::Status, routes, Route};
use rocket_cache_response::CacheResponse;
use std::path::*;

lazy_static! {
    pub static ref FLUTTER_PAGES: Vec<Route> = routes![flutter_index, flutter_file,];
}

#[rocket::get("/flutter/<file..>")]
async fn flutter_file(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    log::info!("flutter_file: {:?}", file);
    let result = match NamedFile::open(Path::new("opt/flutter_web/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => {
            match NamedFile::open(Path::new("../frontends/flutter/build/web/").join(file)).await {
                Ok(file) => Ok(file),
                Err(_) => Err(Status::NotFound),
            }
        }
    };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/flutter")]
pub async fn flutter_index() -> CacheResponse<Result<NamedFile, Status>> {
    let result = match NamedFile::open("opt/flutter_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontends/flutter/build/web/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    };
    CacheResponse::Public {
        responder: result.map_err(|e| {
            log::info!("flutter: {:?}", e);
            Status::NotFound
        }),
        max_age: 60,
        must_revalidate: false,
    }
}
