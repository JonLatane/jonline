use itertools::Itertools;
use jonline_path::create_responder;

use rocket::{
    http::{uri::Origin, Status},
    State,
};
use rocket_cache_response::CacheResponse;
use std::{
    fs,
    path::{Path, PathBuf},
};

use crate::{protos::GetUsersRequest, rpcs, web::RocketState};

use super::{jonline_path, tamagui_path, JonlineResponder, JonlineSummary};

#[rocket::get("/<file..>")]
pub async fn tamagui_file_or_username(
    file: PathBuf,
    state: &State<RocketState>,
    origin: &Origin<'_>,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    log::info!("file_or_username: {:?}", &file);
    let result: Result<JonlineResponder, Status> =
        match fs::read_to_string(Path::new("opt/tamagui_web/").join(file.clone().to_owned())) {
            Ok(body) => Ok(create_responder(file.to_str().unwrap(), body).await),
            Err(_) => {
                match fs::read_to_string(
                    Path::new("../frontends/tamagui/apps/next/out/").join(file.clone()),
                ) {
                    Ok(body) => Ok(create_responder(file.to_str().unwrap(), body).await),
                    Err(_) => {
                        // TODO: Preload social link data (i.e., <meta property="og:title" ... />) for this user.
                        let mut connection = state.pool.get().unwrap();
                        let configuration =
                            rpcs::get_server_configuration_proto(&mut connection).unwrap();
                        let server_name = configuration
                            .server_info
                            .map(|i| i.name)
                            .flatten()
                            .unwrap_or("Jonline".to_string());
                        let path = origin.path();
                        let path_components = path.split('/').collect_vec();
                        // FUck it let's see if this works
                        if path_components.len() != 2 {
                            return tamagui_path(file.to_str().unwrap(), None).await;
                        }

                        let username = Some(
                            path
                                .to_string()
                                .split('/')
                                .last()
                                .unwrap()
                                .to_string(),
                        );
                        let user = rpcs::get_users(
                            GetUsersRequest {
                                username,
                                ..Default::default()
                            },
                            &None,
                            &mut connection,
                        )
                        .ok()
                        .map(|u| u.users.into_iter().next())
                        .flatten();

                        let (page_title, description, avatar) = match user {
                            Some(user) => {
                                let page_title =
                                    format!("{} - User Profile", user.username.clone());
                                let description = user.bio.clone();
                                let avatar =
                                    user.avatar.clone().map(|a| format!("/media/{}", a.id));
                                (page_title, Some(description), avatar)
                            }
                            None => ("User Profile".to_string(), None, None),
                        };

                        let title = Some(format!("{} - {}", page_title, server_name));

                        let summary: Option<JonlineSummary> = Some(JonlineSummary {
                            title,
                            description,
                            image: avatar,
                        });
                        return tamagui_path("[username].html", summary).await;
                    }
                }
            }
        };
    CacheResponse::Public {
        responder: result,
        max_age: 60,
        must_revalidate: false,
    }
}
