use lazy_static::lazy_static;

use rocket::{
    http::{ContentType, MediaType, Status},
    tokio::sync::RwLock,
    Responder,
};
use rocket_cache_response::CacheResponse;
use std::{collections::HashMap, fs, io, path::Path, str::FromStr};

#[derive(Responder, Clone)]
pub struct JonlineResponder {
    pub inner: String,
    pub content_type: ContentType,
}

// Used to provide post/event/group/user link previews for Jonline pages.
#[derive(Clone)]
pub struct JonlineSummary {
    pub title: Option<String>,
    pub description: Option<String>,
    pub image: Option<String>,
}

lazy_static! {
    static ref CACHED_FILES: RwLock<HashMap<String, JonlineResponder>> = {
        let m = HashMap::new();
        RwLock::new(m)
    };
}

pub async fn jonline_path(
    path: &str,
    server_location: &str,
    repo_location: &str,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    let body = jonline_path_responder(path, server_location, repo_location).await;

    CacheResponse::Public {
        responder: body.map_or(Err(Status::NotFound), |body| Ok(body)),
        max_age: 60,
        must_revalidate: false,
    }
}


pub async fn jonline_path_responder(
    path: &str,
    server_location: &str,
    repo_location: &str,
) -> Option<JonlineResponder> {
    let read_guard = CACHED_FILES.read().await;
    let cached_body = read_guard.get(path).cloned();
    drop(read_guard);

    let body = match cached_body {
        Some(body) => Some(body),
        None => {
            let result_string: io::Result<String> = match fs::read_to_string(server_location) {
                Ok(file) => Ok(file),
                Err(_) => match fs::read_to_string(repo_location) {
                    Ok(file) => Ok(file),
                    Err(e) => Err(e),
                },
            };
            match result_string {
                Ok(body) => {
                    let responder = create_responder(path, body).await;
                    Some(responder)
                }
                Err(_) => None,
            }
        }
    };

    body
}

pub async fn create_responder(path: &str, body: String) -> JonlineResponder {
    let extension = Path::new(path)
        .extension()
        .and_then(|s| s.to_str())
        .unwrap_or("txt");
    let content_type = ContentType::from_extension(extension)
        .unwrap_or(ContentType(MediaType::from_str("text/html").unwrap()));
    log::info!(
        "caching: {:?}; extension={:?}, content_type={:?}, body.len()={}",
        path,
        &extension,
        &content_type,
        &body.len()
    );
    let responder = JonlineResponder {
        inner: body,
        content_type,
    };
    // Disable this cache for development purposes.
    // Relying on commenting this out for now, but it would be nice to hide cache writes
    // behind a flag/argument for the `main` of `jonline`.
    CACHED_FILES
        .write()
        .await
        .insert(path.to_string(), responder.clone());
    responder
}
