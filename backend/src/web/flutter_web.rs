use std::path::*;
use rocket::fs::*;

use rocket::{http::Status};

#[rocket::get("/<file..>")]
pub async fn flutter_file(file: PathBuf) -> Result<NamedFile, Status> {
    println!("flutter_file: {:?}", file);
    let real_file = match file.strip_prefix("app/") {
        Ok(p) => p.to_path_buf(),
        Err(_) => file
    };
    match NamedFile::open(Path::new("opt/flutter_web/").join(real_file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../frontend/build/web/").join(real_file)).await {
            Ok(file) => Ok(file),
            Err(_) => Err(Status::NotFound),
        },
    }
}

#[rocket::get("/app")]
pub async fn flutter_index() -> std::io::Result<NamedFile> {
    match NamedFile::open("opt/flutter_web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../frontend/build/web/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    }
}
