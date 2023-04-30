use crate::db_connection::*;
use crate::marshaling::*;
use crate::models;
use crate::protos::Visibility;
use crate::schema;
use crate::schema::media;
use crate::schema::user_access_tokens::dsl as user_access_tokens;
use crate::schema::user_refresh_tokens::dsl as user_refresh_tokens;
use crate::schema::users::dsl as users;
use crate::web::RocketState;

use diesel::*;
use crate::futures::StreamExt;
use rocket::response::stream::ByteStream;
use rocket::{data::ToByteUnit, http::CookieJar, routes, Data, Route, State};
use rocket_cache_response::CacheResponse;

use rocket::http::Status;
use s3::request::ResponseDataStream;
use uuid::Uuid;

lazy_static! {
    pub static ref MEDIA_ENDPOINTS: Vec<Route> = routes![add_media, media_file];
}

#[rocket::post("/media?<jonline_access_token>", data = "<media>")]
pub async fn add_media(
    media: Data<'_>,
    jonline_access_token: Option<String>,
    cookies: &CookieJar<'_>,
    state: &State<RocketState>,
) -> Result<String, Status> {
    log::info!("add_media");
    let user = get_media_user(jonline_access_token, cookies, state)?;
    let uuid = Uuid::new_v4();
    let minio_path = format!("user/{}/{}", user.username, uuid);

    state
        .bucket
        .put_object_stream(&mut media.open(250.mebibytes()), &minio_path)
        .await
        .map_err(|_| Status::InternalServerError)?;

    let media = insert_into(media::table)
        .values(&models::NewMedia {
            user_id: Some(user.id),
            minio_path: minio_path,
            name: None,
            description: None,
            visibility: Visibility::GlobalPublic.to_string_visibility(),
        })
        .get_result::<models::Media>(&mut state.pool.get().unwrap());

    return Ok(media.unwrap().id.to_proto_id());
}

#[rocket::get("/media/<id>?<jonline_access_token>")]
pub async fn media_file(
    id: &str,
    jonline_access_token: Option<String>,
    cookies: &CookieJar<'_>,
    state: &State<RocketState>,
) -> Result<ByteStream![bytes::Bytes], Status> {
    log::info!("media_file: {:?}", id);
    let result = get_media_file(id, jonline_access_token, cookies, state).await;

    match result {
        Ok(mut response_data_stream) => {
            let bytes = response_data_stream.bytes();
            Ok(
                    ByteStream! {
                        while let Some(chunk) = bytes.next().await {
                            yield chunk;
                        }
                    }
                )
        }
        Err(s) => Err(s)
    }
}

async fn get_media_file(
    id: &str,
    jonline_access_token: Option<String>,
    cookies: &CookieJar<'_>,
    state: &State<RocketState>,
) -> Result<ResponseDataStream, Status> {
    let _user = get_media_user(jonline_access_token, cookies, state).ok();

    let media = schema::media::table
        .filter(
            media::id.eq(id
                .to_string()
                .to_db_big_id_or_err("media_id")
                .map_err(|_| Status::BadRequest)?),
        )
        .first::<models::Media>(&mut state.pool.get().unwrap())
        .map_err(|_| Status::NotFound)?;

    let stream = state
        .bucket
        .get_object_stream(media.minio_path.as_str())
        .await
        .map_err(|_| Status::NotFound)?;

    Ok(stream)
}

fn get_media_user(
    jonline_access_token: Option<String>,
    cookies: &CookieJar<'_>,
    state: &State<RocketState>,
) -> Result<models::User, Status> {
    let access_token = match jonline_access_token {
        Some(access_token) => access_token,
        None => match cookies.get("jonline_access_token") {
            Some(access_token) => access_token.value().to_string(),
            None => return Err(Status::Unauthorized),
        },
    };

    let user = get_auth_user(access_token, &mut state.pool.get().unwrap());
    match user {
        Ok(user) => Ok(user),
        Err(status) => Err(status),
    }
}

fn get_auth_user(
    access_token: String,
    conn: &mut PgPooledConnection,
) -> Result<models::User, Status> {
    let user_id = get_auth_user_id(access_token, conn);
    let user: models::User = match user_id {
        Err(status) => return Err(status),
        Ok(user_id) => schema::users::table
            .filter(users::id.eq(user_id))
            .first::<models::User>(conn)
            .unwrap(),
    };
    Ok(user)
}

fn get_auth_user_id(access_token: String, conn: &mut PgPooledConnection) -> Result<i32, Status> {
    delete(
        user_access_tokens::user_access_tokens
            .filter(user_access_tokens::token.eq(access_token.to_owned()))
            .filter(user_access_tokens::expires_at.lt(diesel::dsl::now)),
    )
    .execute(conn)
    .unwrap_or(0);

    let user_id: Result<i32, _> = schema::user_access_tokens::table
        .inner_join(schema::user_refresh_tokens::table)
        .select(user_refresh_tokens::user_id)
        .filter(user_access_tokens::token.eq(access_token))
        .first::<i32>(conn);

    match user_id {
        Ok(user_id) => Ok(user_id),
        Err(_) => Err(Status::Unauthorized),
    }
}
