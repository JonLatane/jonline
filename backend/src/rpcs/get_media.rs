use diesel::*;
use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::media;

pub fn get_media(
    request: GetMediaRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetMediaResponse, Status> {
    log::info!("GetMedia called: ${:?}", request);
    let response = match (request.to_owned().media_id, request.to_owned().user_id) {
        (Some(_), _) => get_by_id(request.to_owned(), user, conn)?,
        (_, Some(_)) => get_user_media(request.to_owned(), user, conn)?,
        _ => {
            return Err(Status::invalid_argument(
                "media_id or user_id must be provided",
            ))
        }
    };
    // log::info!(
    //     "GetMedia::request: {:?}, response: {:?}",
    //     request, response
    // );
    log::info!(
        "GetMedia::request: {:?}, response_length: {:?}",
        request,
        response.media.len()
    );
    Ok(response)
}

fn get_user_media(
    request: GetMediaRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetMediaResponse, Status> {
    log::info!("get_user_media: {:?}", request);
    let requested_user_id = match request.user_id {
        Some(user_id) => user_id.to_db_id_or_err("user_id")?,
        None => match user.as_ref() {
            Some(user) => user.id,
            _ => {
                return Err(Status::invalid_argument(
                    "Must be authenticated, or provide a user ID.",
                ))
            }
        },
    };
    let visibilities = match user.as_ref() {
        Some(user) if requested_user_id == user.id => ALL_VISIBILITIES.to_vec(),
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();

    let media = media::table
        .select(media::all_columns)
        .filter(media::visibility.eq_any(visibilities))
        // .filter(media::name.ilike(format!("{}%", request.media_name.unwrap())))
        .filter(media::user_id.eq(requested_user_id))
        .order(media::created_at.desc())
        .limit(100)
        .offset((request.page * 100).into())
        .load::<models::Media>(conn)
        .unwrap()
        .iter()
        .map(|media| media.to_proto())
        .collect();
    Ok(GetMediaResponse {
        media,
        has_next_page: false,
    })
}

fn get_by_id(
    request: GetMediaRequest,
    user: Option<models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetMediaResponse, Status> {
    log::info!("get_by_id: {:?}", request);
    let visibilities = match user {
        Some(_) => vec![Visibility::ServerPublic, Visibility::GlobalPublic],
        None => vec![Visibility::GlobalPublic],
    }
    .iter()
    .map(|v| v.as_str_name())
    .collect::<Vec<&str>>();
    let media = media::table
        .select(media::all_columns)
        .filter(media::visibility.eq_any(visibilities))
        .filter(
            media::id.eq(request
                .media_id
                .unwrap()
                .to_db_id_or_err("media_id")
                .unwrap()),
        )
        .order(media::created_at.desc())
        .limit(100)
        .offset((request.page * 100).into())
        .load::<models::Media>(conn)
        .unwrap()
        .iter()
        .map(|media| media.to_proto())
        .collect();

    //TODO validate visibility

    Ok(GetMediaResponse {
        media,
        has_next_page: false,
    })
}
