//! Link-preview summaries for short Post/Event URLs: `/{c}{id}` where `c` is any character a username or custom tab
//! can never start with (`/~4rAfoSKAuJo`, `/:…`, ... -- see `rellm.proto`'s routing docs and
//! `Components.Users.startsWithReservedShortUrlCharacter` in the Elm app). Without this the catch-all rendered the
//! username-profile summary for them ("Profile - Server"), whatever the link actually pointed at.

use crate::{
    db_connection::PgPooledConnection,
    protos::{PostContext, ServerConfiguration},
};

use super::{
    RellmSummary, ServerSummaryInfo,
    federated_preview::{federated_summary, parse_federated_id},
    spa_pages::{get_event_from_post, get_post, post_summary},
};

/// `-._~:/?[]@!$&'()*+,;%=` -- what `validate_username` refuses a username or custom tab to start with.
const SHORT_URL_LEAD_CHARACTERS: &str = "-._~:/?[]@!$&'()*+,;%=";

pub fn is_short_url_segment(segment: &str) -> bool {
    segment
        .chars()
        .next()
        .is_some_and(|lead| SHORT_URL_LEAD_CHARACTERS.contains(lead))
}

/// What a short URL's `segment` (leading character included) previews as: the Post or Event it names (the same summary
/// `/post/{id}` and `/event/{id}` give), or -- for a Bluesky/Mastodon post -- what `federated_preview` makes of it.
/// A post that doesn't exist, or that the public can't see, gets the same generic "Post Details | Server" summary as
/// `/post/{id}` does, rather than anything that would reveal it.
pub async fn short_url_summary(
    segment: &str,
    configuration: &ServerConfiguration,
    connection: &mut PgPooledConnection,
) -> Option<RellmSummary> {
    let id: String = segment.chars().skip(1).collect();
    if id.is_empty() {
        return None;
    }
    if let Some(federated) = parse_federated_id(&id) {
        return Some(
            federated_summary(
                &federated,
                &configuration.display_name(),
                configuration.logo_url(),
            )
            .await,
        );
    }
    rellm_short_url_summary(&id, configuration, connection)
}

/// The Rellm half of `short_url_summary`, which only touches the database: the Post/Event `id` names, as
/// `/post/{id}` would preview it.
pub fn rellm_short_url_summary(
    id: &str,
    configuration: &ServerConfiguration,
    connection: &mut PgPooledConnection,
) -> Option<RellmSummary> {
    // An id naming a post on some other Rellm server (`id@host`) isn't one this server can look up.
    let post = if id.contains('@') {
        None
    } else {
        get_post(id.to_string(), connection)
    };
    // An Occasion's id previews as its Event, as `/event/{id}` does -- not as a comment thread on it, which is what
    // `post_summary` would make of an Occasion's own post.
    let post = match post {
        Some(occasion) if occasion.context() == PostContext::Occasion => {
            match get_event_from_post(&occasion.id, connection).and_then(|event| event.post) {
                Some(event_post) => Some(event_post),
                None => Some(occasion),
            }
        }
        other => other,
    };
    post_summary(
        "Post".to_string(),
        post,
        configuration.display_name(),
        configuration.logo_url(),
        None,
        connection,
    )
}
