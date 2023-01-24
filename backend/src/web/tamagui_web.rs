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
        Err(_) => match NamedFile::open(Path::new("../frontends/tamagui/apps/next/out/").join(real_file)).await {
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
    tamagui_path("index.html").await
}

#[rocket::get("/post/<_id_etc..>")]
pub async fn tamagui_post(_id_etc: PathBuf) -> CacheResponse<io::Result<NamedFile>> {
    tamagui_path("post/[id].html").await
}

#[rocket::get("/user/<_id_etc..>")]
pub async fn tamagui_user(_id_etc: PathBuf) -> CacheResponse<io::Result<NamedFile>> {
    tamagui_path("user/[id].html").await
}

async fn tamagui_path(path: &str) -> CacheResponse<io::Result<NamedFile>> {
    let result = match NamedFile::open(format!("opt/tamagui_web/{}", path)).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(format!("../frontends/tamagui/apps/next/out/{}", path)).await {
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