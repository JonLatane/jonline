use super::RocketState;
use crate::rpcs::{get_server_configuration_proto, get_events};
use crate::protos::GetEventsRequest;
use crate::web::external_cdn::configured_frontend_domain;
use crate::marshaling::time_marshaling::ToDbTime;
use rocket::{routes, Route, State};
use rocket::http::uri::Host;
use rocket_cache_response::CacheResponse;
use icalendar::{Calendar, Component, Event};
use chrono::{DateTime, Utc};

lazy_static! {
    pub static ref ICAL_PAGES: Vec<Route> =
        routes![ical_subscription];
}

#[derive(rocket::Responder)]
#[response(content_type = "text/calendar")]
struct ICalResponse(String);

#[rocket::get("/calendar.ics?<user_id>")]
async fn ical_subscription(user_id: Option<String>, state: &State<RocketState>, host: &Host<'_>) -> CacheResponse<ICalResponse> {
    let mut conn = state.pool.get().unwrap();
    let _server_configuration = get_server_configuration_proto(&mut conn).unwrap();
    
    // Get the user_id from the request parameter
    let author_user_id = match user_id {
        Some(id) => id,
        None => return CacheResponse::NoStore(ICalResponse("Error: Missing user_id parameter".to_string())),
    };

    // Create request for get_events RPC
    let request = GetEventsRequest {
        author_user_id: Some(author_user_id),
        ..Default::default()
    };

    // Call get_events RPC (without user for anonymous access)
    let events_response = match get_events(request, &None, &mut conn) {
        Ok(response) => response,
        Err(e) => return CacheResponse::NoStore(ICalResponse(format!("Error fetching events: {}", e))),
    };

    // Create iCal calendar
    let mut calendar = Calendar::new();
    calendar.name("Events Calendar");
    calendar.description("Events from Jonline");

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
            let starts_at = instance.starts_at.as_ref()
                .map(|t| DateTime::<Utc>::from(t.to_db()))
                .unwrap_or(Utc::now());
            
            let ends_at = instance.ends_at.as_ref()
                .map(|t| DateTime::<Utc>::from(t.to_db()))
                .unwrap_or(Utc::now());

            // Create event link
            let event_link = format!("https://{}/event/{}", frontend_domain, instance_id);
            
            // Create description with "via:" link
            let base_description = event_post.content.as_deref().unwrap_or("");
            let description = format!("{}\n\nvia: {}", base_description, event_link);

            // Create iCal event
            let mut ical_event = Event::new();
            ical_event
                .summary(event_post.title.as_deref().unwrap_or("Untitled Event"))
                .description(&description)
                .url(&event_link)
                .starts(starts_at)
                .ends(ends_at);

            // Add location if available
            if let Some(location) = &instance.location {
                if let Some(address) = &location.uniformly_formatted_address {
                    ical_event.location(address);
                }
            }

            calendar.push(ical_event);
        }
    }

    // Generate iCal content
    let ical_content = calendar.to_string();
    
    CacheResponse::NoStore(ICalResponse(ical_content))
}
