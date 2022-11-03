use rocket::fs::*;
use rocket::http::*;
use std::path::*;

use super::flutter_web::flutter_file;

#[rocket::get("/assets/<file..>")]
pub async fn web_asset(file: PathBuf) -> Result<NamedFile, Status> {
    match NamedFile::open(Path::new("templates/assets/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(Path::new("../web/assets/").join(file.to_owned())).await {
            Ok(file) => Ok(file),
            Err(_) => flutter_file(Path::new("assets/").join(file).to_path_buf()).await,
        },
    }
}
