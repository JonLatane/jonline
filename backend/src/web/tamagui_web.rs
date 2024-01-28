use lazy_static::lazy_static;

use rocket::{http::Status, routes, Route, State};
use rocket_cache_response::CacheResponse;

use crate::{
    db_connection::PgPooledConnection,
    protos::{ServerInfo, ServerLogo},
    rpcs,
    web::RocketState,
};

use super::{tamagui_file_or_username, tamagui_path, JonlineResponder, JonlineSummary};

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
        tamagui_file_or_username::tamagui_file_or_username,
    ];
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
            let server_name = configuration
                .clone()
                .server_info
                .map(|i| i.name)
                .flatten()
                .unwrap_or("Jonline".to_string());
            let server_logo_id = configuration
                .server_info
                .unwrap_or(ServerInfo {
                    ..Default::default()
                })
                .logo
                .unwrap_or(ServerLogo {
                    ..Default::default()
                })
                .square_media_id;
            let server_logo = server_logo_id.map(|id| format!("/media/{}", id));
            let path = None;
            let summary: Option<JonlineSummary> =
                ($summary)(connection, server_name, server_logo, path);
            tamagui_path($html_path, summary).await
        }
    };
}

webui!(
    index,
    "/tamagui",
    "index.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Latest - {}", server_name)),
            description: Some("Posts and Events from a Jonline community".to_string()),
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(media, "/media", "media.html");
webui!(
    posts,
    "/posts",
    "posts.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Posts - {}", server_name)),
            description: Some("Posts from a Jonline community".to_string()),
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    events,
    "/events",
    "events.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Events - {}", server_name)),
            description: Some("Searchable, RSVPable Events from a Jonline community".to_string()),
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    about,
    "/about",
    "about.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("About Community - {}", server_name)),
            description: Some("Information a Jonline community".to_string()),
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    about_jonline,
    "/about_jonline",
    "about_jonline.html",
    |_connection: PgPooledConnection,
     _server_name: String,
     _server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some("About Jonline".to_string()),
            description: Some(
                "Information about the Jonline federated social network stack".to_string(),
            ),
            image: None, //server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    post,
    "/post/<_..>",
    "post/[postId].html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Post Details - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    event,
    "/event/<_>",
    "event/[instanceId].html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Event Details - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(user, "/user/<_>", "user/[id].html");
webui!(
    people,
    "/people",
    "people.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("People - {}", server_name)),
            description: Some("User listings for a Jonline community".to_string()),
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    follow_requests,
    "/people/follow_requests",
    "people/follow_requests.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Follow Requests - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_home,
    "/g/<_>",
    "g/[shortname].html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Home/Latest Page - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_posts,
    "/g/<_>/posts",
    "g/[shortname]/posts.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Posts Page - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_post,
    "/g/<_>/p/<_..>",
    "g/[shortname]/p/[postId].html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Post Details - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_events,
    "/g/<_>/events",
    "g/[shortname]/events.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Events Page - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_event,
    "/g/<_>/e/<_>",
    "g/[shortname]/e/[instanceId].html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Event Details - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_members,
    "/g/<_>/members",
    "g/[shortname]/members.html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Members - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_member,
    "/g/<_>/m/<_>",
    "g/[shortname]/m/[username].html",
    |_connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     _path: Option<String>| {
        Some(JonlineSummary {
            title: Some(format!("Group Member Details - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(server, "/server/<_..>", "server/[id].html");
