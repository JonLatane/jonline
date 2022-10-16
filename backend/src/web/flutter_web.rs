use std::path::*;
use rocket::{fs::*, http::Status};

#[rocket::get("/<file..>")]
pub async fn file(file: PathBuf) -> Result<NamedFile, Status> {
    match NamedFile::open(Path::new("opt/flutter_web/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../frontend/build/web/").join(file)).await {
            Ok(file) => Ok(file),
            Err(_) => Err(Status::NotFound),
        },
    }
}
#[rocket::get("/")]
pub async fn index() -> std::io::Result<NamedFile> {
    match NamedFile::open("opt/flutter_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontend/build/web/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    }
}

#[rocket::get("/flutter")]
pub async fn flutter_index() -> std::io::Result<NamedFile> {
    match NamedFile::open("opt/flutter_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontend/build/web/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    }
}
