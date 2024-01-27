use jonline_path::create_responder;
use lazy_static::lazy_static;

use rocket::{routes, tokio::sync::RwLock, Route, State};
use rocket_cache_response::CacheResponse;
use std::{
    collections::HashMap,
    fs,
    path::{Path, PathBuf},
};

use crate::{
    db_connection::PgPooledConnection, models, rpcs, web::RocketState,
};
use rocket::http::Status;

use super::{jonline_path, jonline_path_responder, JonlineResponder, JonlineSummary};

lazy_static! {
    pub static ref TAMAGUI_PAGES: Vec<Route> = routes![
        index,
        media,
        posts,
        events,
        about,
        about_jonline,
        post,
        event,
        user,
        people,
        follow_requests,
        server,
        group_home,
        group_posts,
        group_post,
        group_events,
        group_event,
        group_members,
        group_member,
        tamagui_file_or_username,
    ];
}

#[rocket::get("/<file..>")]
async fn tamagui_file_or_username(
    file: PathBuf,
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
                        let _user: Option<models::User> = None;
                        return tamagui_path("[username].html", None).await;
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

macro_rules! webui {
    // There seems `;` is no longer recognized, so no way to remove `;`
    // and thus redundant_semicolons warnings are triggered.
    // (@inner ;) => { {print!(";");} };
    ($name:tt, $web_route:tt, $html_path:literal) => {
        #[rocket::get($web_route)]
        pub async fn $name() -> CacheResponse<Result<JonlineResponder, Status>> {
            tamagui_path($html_path, None).await
        }
    };
    // (@inner $summary:stmt) => { $summary };
    ($name:tt, $web_route:tt, $html_path:literal, $summary:expr) => {
        #[rocket::get($web_route)]
        pub async fn $name(
            state: &State<RocketState>,
        ) -> CacheResponse<Result<JonlineResponder, Status>> {
            let mut connection = state.pool.get().unwrap();
            let configuration = rpcs::get_server_configuration_proto(&mut connection).unwrap();
            let server_name = configuration.server_info.map(|i| i.name).flatten().unwrap_or("Jonline".to_string());
            let path = None;
            let summary: Option<JonlineSummary> = ($summary)(connection, server_name, path);
            tamagui_path($html_path, summary).await
        }
    };
}

lazy_static! {
    static ref CACHED_FILES: RwLock<HashMap<String, String>> = {
        let m = HashMap::new();
        RwLock::new(m)
    };
}

async fn tamagui_path(
    static_file_path: &str,
    summary: Option<JonlineSummary>,
) -> CacheResponse<Result<JonlineResponder, Status>> {
    let mut template = jonline_path_responder(
        static_file_path,
        &format!("opt/tamagui_web/{}", static_file_path),
        &format!("../frontends/tamagui/apps/next/out/{}", static_file_path),
    )
    .await;

    match (summary, template.as_mut()) {
        (Some(summary), Some(template)) => {
            match summary.title {
                Some(title) => {
                    let updated_body = template.inner.replacen("Jonline Social Link", &title, 1);
                    template.inner = updated_body;
                }
                None => (),
            };
        }
        _ => (),
    };
    CacheResponse::Public {
        responder: template.map_or(Err(Status::NotFound), |body| Ok(body)),
        max_age: 60,
        must_revalidate: false,
    }
}

webui!(
    index,
    "/tamagui",
    "index.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Latest - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(media, "/media", "media.html");
webui!(
    posts,
    "/posts",
    "posts.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Posts - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    events,
    "/events",
    "events.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Events - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    about,
    "/about",
    "about.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("About Community - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    about_jonline,
    "/about_jonline",
    "about_jonline.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some("About Jonline".to_string()),
            description: None,
            image: None, //Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    post,
    "/post/<_..>",
    "post/[postId].html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Post Details - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    event,
    "/event/<_>",
    "event/[instanceId].html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Event Details - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(user, "/user/<_>", "user/[id].html");
webui!(
    people,
    "/people",
    "people.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("People - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    follow_requests,
    "/people/follow_requests",
    "people/follow_requests.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Follow Requests - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_home,
    "/g/<_>",
    "g/[shortname].html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Home/Latest Page - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_posts,
    "/g/<_>/posts",
    "g/[shortname]/posts.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Posts Page - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_post,
    "/g/<_>/p/<_..>",
    "g/[shortname]/p/[postId].html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Post Details - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_events,
    "/g/<_>/events",
    "g/[shortname]/events.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Events Page - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_event,
    "/g/<_>/e/<_>",
    "g/[shortname]/e/[instanceId].html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Event Details - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_members,
    "/g/<_>/members",
    "g/[shortname]/members.html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Members - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(
    group_member,
    "/g/<_>/m/<_>",
    "g/[shortname]/m/[username].html",
    |connection: PgPooledConnection, server_name: String, path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Member Details - {}", server_name)),
            description: None,
            image: Some("/favicon.ico".to_string()),
        })
    }
);
webui!(server, "/server/<_..>", "server/[id].html");
