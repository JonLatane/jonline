use ico;
use rocket::{
    fs::*,
    http::{ContentType, MediaType},
    routes, Route, State,
};
use rocket_cache_response::CacheResponse;
use std::{path::*, str::FromStr};

use crate::{
    protos::{ServerInfo, ServerLogo},
    rpcs::get_server_configuration,
    web::RocketState,
};
use rocket::http::Status;

use super::{load_media_file_data, open_named_file};

lazy_static! {
    pub static ref TAMAGUI_PAGES: Vec<Route> = routes![
        tamagui_index,
        tamagui_media,
        tamagui_posts,
        tamagui_events,
        tamagui_about,
        tamagui_about_jonline,
        tamagui_post,
        tamagui_event,
        tamagui_event_instance,
        tamagui_user,
        tamagui_people,
        tamagui_follow_requests,
        tamagui_server,
        tamagui_group_home,
        tamagui_group_posts,
        tamagui_group_events,
        tamagui_group_post,
        tamagui_group_event,
        tamagui_group_event_instance,
        tamagui_favicon,
        tamagui_file_or_username
    ];
}

#[rocket::get("/<file..>")]
async fn tamagui_file_or_username(file: PathBuf) -> CacheResponse<Result<NamedFile, Status>> {
    log::info!("tamagui_file_or_username: {:?}", file);
    let result = match NamedFile::open(Path::new("opt/tamagui_web/").join(file.to_owned())).await {
        Ok(file) => Ok(file),
        Err(_) => {
            match NamedFile::open(Path::new("../frontends/tamagui/apps/next/out/").join(file)).await
            {
                Ok(file) => Ok(file),
                Err(_) => return tamagui_path("[username].html").await,
            }
        }
    };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/favicon.ico")]
pub async fn tamagui_favicon<'a>(
    state: &State<RocketState>,
) -> Result<CacheResponse<(ContentType, NamedFile)>, Status> {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration(&mut conn).unwrap();
    let logo = configuration
        .server_info
        .unwrap_or(ServerInfo {
            ..Default::default()
        })
        .logo
        .unwrap_or(ServerLogo {
            ..Default::default()
        })
        .square_media_id;
    match logo {
        None => {
            let media_type = ContentType(
                MediaType::from_str("image/ico").map_err(|_| Status::ExpectationFailed)?,
            );
            let favicon_file = match NamedFile::open("opt/tamagui_web/favicon.ico").await {
                Ok(file) => file,
                Err(_) => {
                    match NamedFile::open("../frontends/tamagui/apps/next/out/favicon.ico").await {
                        Ok(file) => file,
                        Err(_) => return Err(Status::ExpectationFailed),
                    }
                }
            };
            Ok(CacheResponse::Public {
                responder: (media_type, favicon_file),
                max_age: 3600 * 12,
                must_revalidate: true,
            })
        }
        Some(square_media_id) => {
            let data = load_media_file_data(&square_media_id, state).await?;
            let mut content_type = &data.0;
            let mut named_filename = &data.1.path().as_os_str().to_str().unwrap().to_string();
            let ico_filename = format!(
                "{}/png-converted-favicon.ico",
                state.tempdir.path().display()
            );
            let ico_content_type = &ContentType(
                MediaType::from_str("image/ico").map_err(|_| Status::ExpectationFailed)?,
            );
            // Convert PNG icons to ICO
            if content_type.to_string().ends_with("png") {
                let mut icon_dir = ico::IconDir::new(ico::ResourceType::Icon);
                // Read PNG file from disk and add it to the collection:
                let file = std::fs::File::open(named_filename).unwrap();
                let image = ico::IconImage::read_png(file).unwrap();
                icon_dir.add_entry(ico::IconDirEntry::encode(&image).unwrap());
                // Alternatively, you can create an IconImage from raw RGBA pixel data
                // (e.g. from another image library):
                let rgba = vec![std::u8::MAX; 4 * 16 * 16];
                let image = ico::IconImage::from_rgba_data(16, 16, rgba);
                icon_dir.add_entry(ico::IconDirEntry::encode(&image).unwrap());
                // Finally, write the ICO file to disk:
                let file = std::fs::File::create(&ico_filename).unwrap();
                icon_dir.write(file).unwrap();

                named_filename = &ico_filename;
                content_type = ico_content_type
            }

            Ok(CacheResponse::Public {
                responder: (content_type.to_owned(), open_named_file(named_filename).await?),
                max_age: 3600 * 12,
                must_revalidate: true,
            })
        }
    }
}

#[rocket::get("/tamagui")]
pub async fn tamagui_index() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("index.html").await
}

#[rocket::get("/media")]
async fn tamagui_media() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("media.html").await
}

#[rocket::get("/posts")]
async fn tamagui_posts() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("posts.html").await
}

#[rocket::get("/events")]
async fn tamagui_events() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("events.html").await
}

#[rocket::get("/about")]
async fn tamagui_about() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("about.html").await
}
#[rocket::get("/about_jonline")]
async fn tamagui_about_jonline() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("about_jonline.html").await
}

#[rocket::get("/post/<_..>")]
async fn tamagui_post() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("post/[postId].html").await
}

#[rocket::get("/event/<_>")]
async fn tamagui_event() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("event/[eventId].html").await
}

#[rocket::get("/event/<_>/i/<_..>")]
async fn tamagui_event_instance() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("event/[eventId]/i/[instanceId].html").await
}

#[rocket::get("/user/<_>")]
async fn tamagui_user() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("user/[id].html").await
}
#[rocket::get("/people")]
async fn tamagui_people() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("people.html").await
}
#[rocket::get("/people/follow_requests")]
async fn tamagui_follow_requests() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("people/follow_requests.html").await
}

#[rocket::get("/g/<_>")]
async fn tamagui_group_home() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("g/[shortname].html").await
}

#[rocket::get("/g/<_>/posts")]
async fn tamagui_group_posts() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("g/[shortname]/posts.html").await
}

#[rocket::get("/g/<_>/events")]
async fn tamagui_group_events() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("g/[shortname]/events.html").await
}

#[rocket::get("/g/<_>/p/<_..>")]
async fn tamagui_group_post() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("g/[shortname]/p/[postId].html").await
}

#[rocket::get("/g/<_>/e/<_>")]
async fn tamagui_group_event() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("g/[shortname]/e/[eventId].html").await
}

#[rocket::get("/g/<_>/e/<_>/i/<_..>")]
async fn tamagui_group_event_instance() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("g/[shortname]/e/[eventId]/i/[instanceId].html").await
}

#[rocket::get("/server/<_..>")]
async fn tamagui_server() -> CacheResponse<Result<NamedFile, Status>> {
    tamagui_path("server/[id].html").await
}

async fn tamagui_path(path: &str) -> CacheResponse<Result<NamedFile, Status>> {
    let result = match NamedFile::open(format!("opt/tamagui_web/{}", path)).await {
        Ok(file) => Ok(file),
        Err(_) => {
            match NamedFile::open(format!("../frontends/tamagui/apps/next/out/{}", path)).await {
                Ok(file) => Ok(file),
                Err(e) => Err(e),
            }
        }
    };
    CacheResponse::Public {
        responder: result.map_err(|e| {
            log::info!("tamagui_path: {:?}", e);
            Status::NotFound
        }),
        max_age: 60,
        must_revalidate: false,
    }
}
