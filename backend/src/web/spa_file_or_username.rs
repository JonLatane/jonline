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

use crate::{
    protos::{GetUsersRequest, Permission},
    rpcs,
    web::RocketState,
};

use super::{
    jonline_path, root_app, spa_prefix, spa_web_path, strip_spa_prefix, JonlineResponder,
    JonlineSummary, SpaApp,
};

/// Fallback for arbitrary Tamagui build assets and username shortcut links
/// (e.g. "/someuser"). Reading the asset itself is always done from the
/// Tamagui build directories (that's the only place these static exports
/// live), but once we fall through to rendering a page (rather than a raw
/// file), an unprefixed request defers to `root_app`/`WebUserInterface` like
/// the rest of `spa_pages.rs`, so e.g. "/someuser" renders Elm when the
/// server is configured for it. Only ever mounted at root (see rocket.rs).
///
/// `rank = 20`: this route's own shape ("/<file..>", fully dynamic) gives it
/// a better default Rocket rank than `elm_web::elm_file`'s ("/elm/<file..>",
/// static + dynamic), so without an explicit override it would steal asset
/// requests like "/elm/dist/elm.js" out from under that route -- this is
/// meant to be the last-resort fallback of the whole route table (it matches
/// literally any path), so it should always lose ties.
#[rocket::get("/<file..>", rank = 20)]
pub async fn spa_file_or_username(
    file: PathBuf,
    state: &State<RocketState>,
    origin: &Origin<'_>,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    log::info!("file_or_username: {:?}", &file);
    // See spa_web_path.rs: Next bakes a single fixed basePath into a build, so
    // "/" and "/tamagui" are served from two separate exports on disk. This
    // route is only ever mounted at root, so under the "/tamagui" prefix
    // `file` still carries a leading "tamagui" component that must be
    // stripped before joining it against either variant's directory -- that
    // directory already stands in for the prefix.
    let is_tamagui = spa_prefix(origin.path().as_str()) == Some(SpaApp::Tamagui);
    let (opt_dir, repo_dir) = if is_tamagui {
        ("tamagui_web_tamagui", "out-tamagui")
    } else {
        ("tamagui_web", "out")
    };
    let relative_file: PathBuf = if is_tamagui {
        file.strip_prefix("tamagui").unwrap_or(&file).to_path_buf()
    } else {
        file.clone()
    };
    // Namespaced so the two variants (which otherwise share relative filenames)
    // don't collide in jonline_path's cache.
    let cache_key = format!("{}/{}", opt_dir, relative_file.to_str().unwrap());
    let result: Result<JonlineResponder, Status> =
        match fs::read_to_string(Path::new(&format!("opt/{}/", opt_dir)).join(&relative_file)) {
            Ok(body) => Ok(create_responder(&cache_key, body).await),
            Err(_) => {
                match fs::read_to_string(
                    Path::new(&format!("../frontends/tamagui/apps/next/{}/", repo_dir)).join(&relative_file),
                ) {
                    Ok(body) => Ok(create_responder(&cache_key, body).await),
                    Err(_) => {
                        // TODO: Preload social link data (i.e., <meta property="og:title" ... />) for this user.
                        let mut connection = state.pool.get().unwrap();
                        let configuration =
                            rpcs::get_server_configuration_proto(&mut connection).unwrap();
                        let server_info = configuration.server_info.unwrap_or_default();
                        let app = spa_prefix(origin.path().as_str())
                            .unwrap_or_else(|| root_app(&server_info));
                        let server_name = server_info.name.clone().unwrap_or("Jonline".to_string());
                        let path = strip_spa_prefix(origin.path().as_str());
                        let path_components = path.split('/').collect_vec();
                        // FUck it let's see if this works
                        if path_components.len() != 2 {
                            return spa_web_path(
                                app,
                                relative_file.to_str().unwrap(),
                                None,
                                is_tamagui,
                            )
                            .await;
                        }

                        let username =
                            Some(path.split('/').last().unwrap().to_string());
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
                                let is_business =
                                    user.permissions.contains(&(Permission::Business as i32));
                                let page_title = format!(
                                    "{} - {}",
                                    match user.real_name {
                                        name if name != "" => name,
                                        _ => user.username.clone(),
                                    },
                                    // user.username.clone(),
                                    if is_business { "Business Profile" } else { "Profile" }
                                );
                                let description = user.bio.clone();
                                let avatar =
                                    user.avatar.clone().map(|a| format!("/media/{}", a.id));
                                (page_title, Some(description), avatar)
                            }
                            None => ("Profile".to_string(), None, None),
                        };

                        let title = Some(format!("{} - {}", page_title, server_name));

                        let summary: Option<JonlineSummary> = Some(JonlineSummary {
                            title,
                            description,
                            image: avatar,
                        });
                        return spa_web_path(app, "[username].html", summary, is_tamagui).await;
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
