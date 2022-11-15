use rocket::fs::*;
use rocket::http::*;
use std::path::*;
use rocket_cache_response::CacheResponse;

use super::flutter_web::flutter_file;

#[rocket::get("/assets/<file..>")]
pub async fn web_asset(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    match NamedFile::open(Path::new("templates/assets/").join(file.to_owned())).await {
        Ok(file) => CacheResponse::Public {
            responder: Ok(file),
            max_age: 60,
            must_revalidate: false,
        },
        Err(_) => match NamedFile::open(Path::new("../web/assets/").join(file.to_owned())).await {
            Ok(file) => CacheResponse::Public {
                responder: Ok(file),
                max_age: 60,
                must_revalidate: false,
            },
            Err(_) => flutter_file(Path::new("assets/").join(file).to_path_buf()).await,
        },
    }
}
