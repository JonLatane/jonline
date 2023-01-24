use std::path::*;
use rocket::fs::*;
use rocket_cache_response::CacheResponse;


use rocket::http::Status;
use std::io;

#[rocket::get("/<file..>")]
pub async fn tamagui_file(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    println!("tamagui_file: {:?}", file);
    let real_file = match file.strip_prefix("app/") {
        Ok(p) => p.to_path_buf(),
        Err(_) => file
    };
    let result = match NamedFile::open(Path::new("opt/tamagui_web/").join(real_file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../tamagui-frontend/apps/next/out/").join(real_file)).await {
            Ok(file) => Ok(file),
            Err(_) => Err(Status::NotFound),
        },
    };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/tamagui")]
pub async fn tamagui_index() -> CacheResponse<io::Result<NamedFile>> {
    let result = match NamedFile::open("opt/tamagui_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../tamagui-frontend/apps/next/out/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}
