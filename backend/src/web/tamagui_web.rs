use lazy_static::lazy_static;

use rocket::{
    http::{
        uri::{Origin, Path},
        Status,
    },
    routes, Route, State,
};
use rocket_cache_response::CacheResponse;

use crate::{
    db_connection::PgPooledConnection,
    protos::{GetPostsRequest, MediaReference, ServerInfo, ServerLogo},
    rpcs,
    web::RocketState,
};
use crate::{
    itertools::Itertools,
    protos::{GetEventsRequest, Post},
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
            origin: &Origin<'_>,
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
            let path = origin.path();
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let path_components = path.split('/').collect_vec();
        if path_components.len() < 3 {
            return None;
        }
        let post_id = path_components[2].to_string();
        let post = rpcs::get_posts(
            GetPostsRequest {
                post_id: Some(post_id),
                ..Default::default()
            },
            &None,
            &mut connection,
        )
        .ok()
        .map(|r| r.posts.into_iter().next())
        .flatten();

        post_summary("Post".to_string(), post, server_name, server_logo, None)
        // let basic_logo = server_logo.or(Some("/favicon.ico".to_string()));
        // let (title, description, image) = match post {
        //     Some(post) => {
        //         let title = post
        //             .title
        //             .map_or(format!("Post Details - {}", server_name), |title| {
        //                 format!("{} - Post Details - {}", title.clone(), server_name)
        //             });
        //         // let image = None;
        //         let image_ref: Option<&MediaReference> = post
        //             .media
        //             .iter()
        //             .find(|m| m.content_type.starts_with("image"));
        //         let image = image_ref.map_or(basic_logo, |mr| Some(format!("/media/{}", mr.id)));
        //         (title, post.content.clone(), image)
        //     }
        //     None => (format!("Post Details - {}", server_name), None, basic_logo),
        // };

        // Some(JonlineSummary {
        //     title: Some(title),
        //     description,
        //     image,
        // })
    }
);
webui!(
    event,
    "/event/<_>",
    "event/[instanceId].html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let path_components = path.split('/').collect_vec();
        if path_components.len() < 3 {
            return None;
        }
        let event_instance_id = path_components[2].to_string();
        let event = rpcs::get_events(
            GetEventsRequest {
                event_instance_id: Some(event_instance_id),
                ..Default::default()
            },
            &None,
            &mut connection,
        )
        .ok()
        .map(|r| r.events.into_iter().next())
        .flatten();
        let post = event.map(|e| e.post).flatten();

        post_summary("Event".to_string(), post, server_name, server_logo, None)

        // let basic_logo = server_logo.or(Some("/favicon.ico".to_string()));
        // let (title, description, image) = match post {
        //     Some(post) => {
        //         let title = post
        //             .title
        //             .map_or(format!("Event Details - {}", server_name), |title| {
        //                 format!("{} - Event Details - {}", title.clone(), server_name)
        //             });
        //         // let image = None;
        //         let image_ref: Option<&MediaReference> = post
        //             .media
        //             .iter()
        //             .find(|m| m.content_type.starts_with("image"));
        //         let image = image_ref.map_or(basic_logo, |mr| Some(format!("/media/{}", mr.id)));
        //         (title, post.content.clone(), image)
        //     }
        //     None => (format!("Event Details - {}", server_name), None, basic_logo),
        // };

        // Some(JonlineSummary {
        //     title: Some(title),
        //     description,
        //     image,
        // })
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
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
     _path: Path| {
        Some(JonlineSummary {
            title: Some(format!("Group Member Details - {}", server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(server, "/server/<_..>", "server/[id].html");

fn post_summary(
    entity_type: String,
    post: Option<Post>,
    server_name: String,
    server_logo: Option<String>,
    _group_name: Option<String>,
) -> Option<JonlineSummary> {
    let basic_logo = server_logo.or(Some("/favicon.ico".to_string()));
    let (title, description, image) = match post {
        Some(post) => {
            let title = post.title.map_or(
                format!("{} Details - {}", entity_type, server_name),
                |title| {
                    format!(
                        "{} - {} Details - {}",
                        title.clone(),
                        entity_type,
                        server_name
                    )
                },
            );
            let image_ref: Option<&MediaReference> = post
                .media
                .iter()
                .find(|m| m.content_type.starts_with("image"));
            let image = image_ref.map_or(basic_logo, |mr| Some(format!("/media/{}", mr.id)));
            (title, post.content.clone(), image)
        }
        None => (
            format!("{} Details - {}", entity_type, server_name),
            None,
            basic_logo,
        ),
    };

    Some(JonlineSummary {
        title: Some(title),
        description,
        image,
    })
}
