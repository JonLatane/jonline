use rocket::*;
use rocket::fs::*;


#[get("/web")]
pub async fn home() -> std::io::Result<NamedFile> {
    match NamedFile::open("opt/web/index.html").await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open("../web/index.html").await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    }
}
