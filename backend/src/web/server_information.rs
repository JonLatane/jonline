use std::str::FromStr;

use super::{load_media_file_data, open_named_file, RocketState};
use crate::{
    protos::{ServerInfo, ServerLogo},
    rpcs::{get_server_configuration_proto, get_service_version},
};
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use rocket::{
    fs::NamedFile,
    http::{ContentType, MediaType, Status},
    response::Redirect,
    routes, uri, Route, State,
};
use rocket_cache_response::CacheResponse;
use base64::{Engine, prelude::BASE64_STANDARD};

lazy_static! {
    pub static ref INFORMATIONAL_PAGES: Vec<Route> =
        routes![info_shield, docs, documentation, protocol_docs, favicon];
}

#[rocket::get("/info_shield")]
async fn info_shield(state: &State<RocketState>) -> Result<CacheResponse<Redirect>, Status> {
    let service_version = get_service_version().unwrap().version;

    let mut conn = state.pool.get().unwrap();
    let server_configuration = get_server_configuration_proto(&mut conn).unwrap();
    let server_info = server_configuration.server_info.as_ref().unwrap();
    let server_name = server_info.name.as_ref().unwrap();
    let colors = server_info.colors.as_ref().unwrap();
    let primary_color_int = colors.primary.unwrap();
    let nav_color_int = colors.navigation.unwrap();
    let mut primary_color = format!("{:x}", primary_color_int);
    while primary_color.len() < 6 {
        primary_color = format!("0{}", primary_color);
    }
    while primary_color.len() > 6 {
        primary_color = format!("{}", &primary_color[1..]);
    }
    let mut nav_color = format!("{:x}", nav_color_int);
    while nav_color.len() < 6 {
        nav_color = format!("0{}", nav_color);
    }
    while nav_color.len() > 6 {
        nav_color = format!("{}", &nav_color[1..]);
    }

    let encoded_server_name = utf8_percent_encode(&server_name, NON_ALPHANUMERIC).to_string();

    let logo_media_id = server_info
        .logo
        .as_ref()
        .map(|l| l.square_media_id.clone())
        .flatten();
    let logo_media_data_url = match logo_media_id {
        Some(ref logo_media_id) => {
            let logo_data = load_media_file_data(logo_media_id, state).await?;
            let content_type = logo_data.0;
            match content_type.to_string().as_str() {
                "image/svg+xml" => {
                    let named_filename =
                        &logo_data.1.path().as_os_str().to_str().unwrap().to_string();
                    let logo_file = std::fs::File::open(named_filename).unwrap();
                    let logo_bytes = std::io::Read::bytes(logo_file)
                        .collect::<Result<Vec<u8>, _>>()
                        .unwrap();
                    let media_data_url = format!(
                        "data:{};base64,{}",
                        content_type,
                        BASE64_STANDARD.encode(&logo_bytes)
                    );
                    Some(media_data_url)
                }
                _ => None,
            }
        }
        None => None,
    };
    let encoded_logo = match logo_media_data_url {
        Some(logo_media_data_url) => {
            let encoded_logo =
                utf8_percent_encode(&logo_media_data_url, NON_ALPHANUMERIC).to_string();
            Some(encoded_logo)
        }
        None => None,
    };

    match encoded_logo {
        Some(encoded_logo) => Ok(CacheResponse::NoStore(Redirect::temporary(format!(
                "https://img.shields.io/badge/{}-v{}-information?style=for-the-badge&labelColor={}&color={}&logo={}",
                encoded_server_name.replace("-", "--"), service_version.replace("-", "--"), primary_color, nav_color, encoded_logo
            )))),
        None =>  Ok(CacheResponse::NoStore(Redirect::temporary(format!(
            "https://img.shields.io/badge/{}-v{}-information?style=for-the-badge&labelColor={}&color={}",
            encoded_server_name.replace("-", "--"), service_version.replace("-", "--"), primary_color, nav_color
        ))))
    }
}

#[rocket::get("/documentation")]
fn documentation() -> Redirect {
    Redirect::to(uri!(docs))
}

#[rocket::get("/docs")]
fn docs() -> Redirect {
    Redirect::to(uri!(protocol_docs))
}

#[rocket::get("/docs/protocol")]
pub async fn protocol_docs() -> CacheResponse<Result<NamedFile, Status>> {
    docs_path("protocol.html").await
}

async fn docs_path(path: &str) -> CacheResponse<Result<NamedFile, Status>> {
    let result = match NamedFile::open(format!("opt/docs/{}", path)).await {
        Ok(file) => Ok(file),
        Err(_) => match NamedFile::open(format!("../docs/{}", path)).await {
            Ok(file) => Ok(file),
            Err(e) => Err(e),
        },
    };
    CacheResponse::Public {
        responder: result.map_err(|e| {
            log::error!("docs_path: {:?}", e);
            Status::NotFound
        }),
        max_age: 60,
        must_revalidate: false,
    }
}

#[rocket::get("/favicon.ico")]
async fn favicon<'a>(
    state: &State<RocketState>,
) -> Result<CacheResponse<(ContentType, NamedFile)>, Status> {
    let mut conn = state.pool.get().unwrap();
    let configuration = get_server_configuration_proto(&mut conn).unwrap();
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
            let favicon_file = match NamedFile::open("opt/web/favicon.ico").await {
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
                responder: (
                    content_type.to_owned(),
                    open_named_file(named_filename).await?,
                ),
                max_age: 3600 * 12,
                must_revalidate: true,
            })
        }
    }
}
