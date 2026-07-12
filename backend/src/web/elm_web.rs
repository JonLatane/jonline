use rocket::{fs::*, http::Status, routes, Route};
use rocket_cache_response::CacheResponse;
use std::path::*;

lazy_static! {
    pub static ref ELM_PAGES: Vec<Route> = routes![elm_index, elm_file,];
}

#[rocket::get("/elm/<file..>")]
async fn elm_file(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    log::info!("elm_file: {:?}", file);
    let result = match NamedFile::open(Path::new("opt/elm_web/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => {
            match NamedFile::open(Path::new("../frontends/elm-spa/public/").join(file)).await {
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

#[rocket::get("/elm")]
pub async fn elm_index() -> CacheResponse<Result<NamedFile, Status>> {
    let result = match NamedFile::open("opt/elm_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontends/elm-spa/public/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    };
    CacheResponse::Public {
        responder: result.map_err(|e| {
            log::info!("elm: {:?}", e);
            Status::NotFound
        }),
        max_age: 60,
        must_revalidate: false,
    }
}
