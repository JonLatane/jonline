use std::path::*;
use rocket::fs::*;
use rocket_cache_response::CacheResponse;


use rocket::http::Status;

#[rocket::get("/<file..>")]
pub async fn tamagui_file(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    println!("tamagui_file: {:?}", file);
    let result = match NamedFile::open(Path::new("opt/tamagui_web/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../frontends/tamagui/apps/next/out/").join(file)).await {
            Ok(file) => Ok(file),
            Err(_) => return tamagui_path("[id].html").await//Err(Status::NotFound),
        },
    };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/tamagui")]
pub async fn tamagui_index() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("index.html").await
}

#[rocket::get("/post/<_id_etc..>")]
pub async fn tamagui_post(_id_etc: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("post/[id].html").await
}

#[rocket::get("/user/<_id_etc..>")]
pub async fn tamagui_user(_id_etc: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("user/[id].html").await
}


#[rocket::get("/server/<_id_etc..>")]
pub async fn tamagui_server(_id_etc: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("server/[id].html").await
}

async fn tamagui_path(path: &str) -> CacheResponse<Result<NamedFile, Status>> {
    let result = match NamedFile::open(format!("opt/tamagui_web/{}", path)).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(format!("../frontends/tamagui/apps/next/out/{}", path)).await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    };
    CacheResponse::Public {
        responder: result.map_err(|e| {
            println!("tamagui_path: {:?}", e);
            Status::NotFound
        }),
        max_age: 60,
        must_revalidate: false,
    }
}