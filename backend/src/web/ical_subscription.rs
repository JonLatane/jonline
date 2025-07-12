use super::RocketState;
use crate::marshaling::ToDbTime;
use crate::protos::{GetEventsRequest, GetUsersRequest, User};
use crate::rpcs::{get_events, get_server_configuration_proto, get_users};
use crate::web::external_cdn::configured_frontend_domain;
use chrono::{DateTime, Utc};
use icalendar::{Calendar, Component, Event, EventLike};
use rocket::http::uri::Host;
use rocket::{routes, Route, State};
use rocket_cache_response::CacheResponse;

lazy_static! {
    pub static ref ICAL_PAGES: Vec<Route> = routes![ical_subscription];
}

#[derive(rocket::Responder)]
#[response(content_type = "text/calendar")]
struct ICalResponse(String);

#[rocket::get("/calendar.ics?<user_id>")]
async fn ical_subscription(
    user_id: Option<String>,
    state: &State<RocketState>,
    host: &Host<'_>,
) -> CacheResponse<ICalResponse> {
    let mut conn = state.pool.get().unwrap();
    let server_configuration = get_server_configuration_proto(&mut conn).unwrap();
    let server_name = server_configuration
        .clone()
        .server_info
        .map(|i| i.name)
        .flatten()
        .unwrap_or("Jonline".to_string());
    // let server_logo_id = server_configuration
    //     .server_info
    //     .unwrap_or(ServerInfo {
    //         ..Default::default()
    //     })
    //     .logo
    //     .unwrap_or(ServerLogo {
    //         ..Default::default()
    //     })
    //     .square_media_id;
    // let server_logo = server_logo_id.map(|id| format!("/media/{}", id));

    let author_user: Option<User> = match &user_id {
        Some(id) if !id.is_empty() => {
            let request = GetUsersRequest {
                user_id: user_id.clone(),
                ..Default::default()
            };
            match get_users(request, &None, &mut conn) {
                Ok(response) => response.users.into_iter().next(),
                Err(_) => None,
            }
        }
        _ => None, // Anonymous access
    };
    let author_user_name = match &author_user {
        Some(user) => match &user.real_name {
            name if name != "" => name.clone(),
            _ => user.username.clone(),
        },
        //user.real_name.clone().unwrap_or(format!("User {}", user.id)),
        None => format!("User {}", &user_id.clone().unwrap_or("".to_string())),
    };

    // Create request for get_events RPC
    let request = GetEventsRequest {
        author_user_id: user_id.clone(),
        // time_filter: Some(TimeFilter {
        //     starts_after: Some(Utc::now().sub.to_db_time()),
        //     ..Default::default()
        // }),
        ..Default::default()
    };

    // Call get_events RPC (without user for anonymous access)
    let events_response = match get_events(request, &None, &mut conn) {
        Ok(response) => response,
        Err(e) => {
            return CacheResponse::NoStore(ICalResponse(format!("Error fetching events: {e}")))
        }
    };

    // Create iCal calendar
    let mut calendar = Calendar::new();
    match user_id {
        Some(_) => calendar.name(&format!(
            "{author_user_name} | Event Calendar | {server_name}"
        )),
        None => calendar.name(&format!("{server_name} | Event Calendar")),
    };
    // calendar.name(&format!("{server_name} | Events Calendar"));
    // calendar.description("Events from Jonline");

    // Get the frontend domain for event links
    let frontend_domain = configured_frontend_domain(state, host);

    // Process each event and its instances
    for event in events_response.events {
        let event_post = match &event.post {
            Some(post) => post,
            None => continue, // Skip events without posts
        };

        for instance in &event.instances {
            let instance_id = &instance.id;

            // Convert timestamps to DateTime<Utc>
            let starts_at = instance
                .starts_at
                .as_ref()
                .map(|t| DateTime::<Utc>::from(t.to_db()))
                .unwrap_or(Utc::now());

            let ends_at = instance
                .ends_at
                .as_ref()
                .map(|t| DateTime::<Utc>::from(t.to_db()))
                .unwrap_or(Utc::now());

            // Create event link
            let event_link = format!("https://{frontend_domain}/event/{instance_id}");

            // Create description with "via:" link
            let base_description = event_post.content.as_deref().unwrap_or("");
            // let event_post_link = event_post.link.clone()).flatten();
            let description = match &event_post.link {
                Some(link) => format!("{base_description}\n\nvia: {link}"),
                None => base_description.to_string(),
            };
            // format!("{base_description}\n\nvia: {event_link}");

            // Create iCal event
            let mut ical_event = Event::new();
            ical_event
                .summary(event_post.title.as_deref().unwrap_or("Untitled Event"))
                .description(&description)
                .url(event_post.link.as_ref().unwrap_or(&event_link))
                .starts(starts_at)
                .ends(ends_at);

            // Add location if available
            if let Some(location) = &instance.location {
                ical_event.location(&location.uniformly_formatted_address);
            }

            calendar.push(ical_event);
        }
    }

    // Generate iCal content
    let ical_content = calendar.to_string();

    CacheResponse::NoStore(ICalResponse(ical_content))
}
