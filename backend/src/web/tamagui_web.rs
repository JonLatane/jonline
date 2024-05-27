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
    protos::{Event, GetPostsRequest, MediaReference, ServerInfo, ServerLogo},
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
        let post = match federated_path_component(&path, 2) {
            Some(FederatedId::Local(post_id)) => get_post(post_id, &mut connection),
            Some(FederatedId::Federated(_, _)) => None,
            None => return None,
        };

        post_summary("Post".to_string(), post, server_name, server_logo, None)
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
        let event = match federated_path_component(&path, 2) {
            Some(FederatedId::Local(instance_id)) => get_event(instance_id, &mut connection),
            Some(FederatedId::Federated(_, _)) => None,
            None => return None,
        };
        let post = event.map(|e| e.post).flatten();

        post_summary("Event".to_string(), post, server_name, server_logo, None)
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
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let group_name = group_name(&path, &mut connection);

        Some(JonlineSummary {
            title: Some(format!("{}: Latest - {}", group_name, server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_posts,
    "/g/<_>/posts",
    "g/[shortname]/posts.html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let group_name = group_name(&path, &mut connection);

        Some(JonlineSummary {
            title: Some(format!("{}: Posts - {}", group_name, server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_post,
    "/g/<_>/p/<_..>",
    "g/[shortname]/p/[postId].html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let group_name = group_name(&path, &mut connection);

        let post = match federated_path_component(&path, 4) {
            Some(FederatedId::Local(post_id)) => get_post(post_id, &mut connection),
            Some(FederatedId::Federated(_, _)) => None,
            None => return None,
        };

        post_summary(
            "Post".to_string(),
            post,
            server_name,
            server_logo,
            Some(group_name),
        )
    }
);
webui!(
    group_events,
    "/g/<_>/events",
    "g/[shortname]/events.html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let shortname = path_component(&path, 2).unwrap();
        let group_name = rpcs::get_groups(
            crate::protos::GetGroupsRequest {
                group_shortname: Some(shortname),
                ..Default::default()
            },
            &None,
            &mut connection,
        )
        .ok()
        .map(|r| r.groups.get(0).map(|g| g.name.clone()))
        .flatten()
        .unwrap_or("Group".to_string());
        Some(JonlineSummary {
            title: Some(format!("{}: Events - {}", group_name, server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);

webui!(
    group_event,
    "/g/<_>/e/<_>",
    "g/[shortname]/e/[instanceId].html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let group_name = group_name(&path, &mut connection);

        let event = match federated_path_component(&path, 4) {
            Some(FederatedId::Local(instance_id)) => get_event(instance_id, &mut connection),
            Some(FederatedId::Federated(_, _)) => None,
            None => return None,
        };
        let post = event.map(|e| e.post).flatten();
        post_summary(
            "Event".to_string(),
            post,
            server_name,
            server_logo,
            Some(group_name),
        )
    }
);
webui!(
    group_members,
    "/g/<_>/members",
    "g/[shortname]/members.html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let group_name = group_name(&path, &mut connection);

        Some(JonlineSummary {
            title: Some(format!("{}: Members - {}", group_name, server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(
    group_member,
    "/g/<_>/m/<_>",
    "g/[shortname]/m/[username].html",
    |mut connection: PgPooledConnection,
     server_name: String,
     server_logo: Option<String>,
     path: Path| {
        let group_name = group_name(&path, &mut connection);

        Some(JonlineSummary {
            title: Some(format!("{} - Member Details - {}", group_name, server_name)),
            description: None,
            image: server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
webui!(server, "/server/<_..>", "server/[id].html");

webui!(
    event_ai,
    "/event_ai",
    "event_ai.html",
    |_connection: PgPooledConnection,
     _server_name: String,
     _server_logo: Option<String>,
     _path: Path| {
        Some(JonlineSummary {
            title: Some("Jonline AI Event Importer".to_string()),
            description: Some(
                "AI-powered bulk import of Events for Jonline".to_string(),
            ),
            image: None, //server_logo.or(Some("/favicon.ico".to_string())),
        })
    }
);
fn group_name(path: &Path, connection: &mut PgPooledConnection) -> String {
    match federated_path_component(&path, 2) {
        Some(FederatedId::Local(shortname)) => rpcs::get_groups(
            crate::protos::GetGroupsRequest {
                group_shortname: Some(shortname.clone()),
                ..Default::default()
            },
            &None,
            connection,
        )
        .ok()
        .map(|r| r.groups.get(0).map(|g| g.name.clone()))
        .flatten()
        .unwrap_or(shortname.clone()),
        Some(FederatedId::Federated(ref shortname, _)) => shortname.clone(),
        None => "Group".to_string(),
    }
}

fn post_summary(
    entity_type: String,
    post: Option<Post>,
    server_name: String,
    server_logo: Option<String>,
    group_name: Option<String>,
) -> Option<JonlineSummary> {
    let basic_logo = server_logo.or(Some("/favicon.ico".to_string()));
    let server_and_group_name = match group_name {
        Some(group_name) => format!("{} - {}", group_name, server_name),
        None => server_name,
    };
    let (title, description, image) = match post {
        Some(post) => {
            let title = post.title.map_or(
                format!("{} Details - {}", entity_type, server_and_group_name),
                |title| {
                    format!(
                        "{} - {} Details - {}",
                        title.clone(),
                        entity_type,
                        server_and_group_name
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
            format!("{} Details - {}", entity_type, server_and_group_name),
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

fn get_post(post_id: String, connection: &mut PgPooledConnection) -> Option<Post> {
    let post = rpcs::get_posts(
        GetPostsRequest {
            post_id: Some(post_id),
            ..Default::default()
        },
        &None,
        connection,
    )
    .ok()
    .map(|r| r.posts.into_iter().next())
    .flatten();
    post
}

fn get_event(event_instance_id: String, connection: &mut PgPooledConnection) -> Option<Event> {
    let event = rpcs::get_events(
        GetEventsRequest {
            event_instance_id: Some(event_instance_id),
            ..Default::default()
        },
        &None,
        connection,
    )
    .ok()
    .map(|r| r.events.into_iter().next())
    .flatten();
    event
}

enum FederatedId {
    Local(String),
    Federated(String, String),
}

fn federated_path_component(path: &Path, index: usize) -> Option<FederatedId> {
    let path_component = path_component(path, index);
    match path_component {
        Some(path_component) if path_component.split('@').count() == 1 => {
            Some(FederatedId::Local(path_component))
        }
        Some(path_component) => {
            let mut path_components = path_component.split('@');
            let username = path_components.next().unwrap().to_string();
            let domain = path_components.next().unwrap().to_string();
            Some(FederatedId::Federated(username, domain))
        }
        _ => None,
    }
}

fn path_component(path: &Path, index: usize) -> Option<String> {
    let path_components = path.split('/').collect_vec();
    if path_components.len() <= index {
        return None;
    }
    Some(path_components[index].to_string())
}
