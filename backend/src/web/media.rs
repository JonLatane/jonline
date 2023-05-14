use crate::db_connection::*;
use crate::marshaling::*;
use crate::models;
use crate::protos::Visibility;
use crate::schema;
use crate::schema::media;
use crate::schema::user_access_tokens::dsl as user_access_tokens;
use crate::schema::user_refresh_tokens::dsl as user_refresh_tokens;
use crate::schema::users::dsl as users;
use crate::web::headers::{AuthHeader, ContentTypeHeader, FilenameHeader};
use crate::web::RocketState;
// use crate::tokio_stream::StreamExt;
// use crate::bytes::Bytes;
use log::info;
use rocket::fs::NamedFile;
// use s3::request::ResponseDataStream;

use diesel::*;
// use rocket::response::stream::ByteStream;
use rocket::{data::ToByteUnit, http::CookieJar, routes, Data, Route, State};

use rocket::http::Status;
// use tokio::io::AsyncWriteExt;
use uuid::Uuid;

lazy_static! {
    pub static ref MEDIA_ENDPOINTS: Vec<Route> = routes![add_media_options, add_media, media_file];
}


#[rocket::options("/media")]
pub async fn add_media_options() -> &'static str {
    return "";
}

#[rocket::post("/media", data = "<media>")]
pub async fn add_media(
    media: Data<'_>,
    cookies: &CookieJar<'_>,
    state: &State<RocketState>,
    auth_header: Option<AuthHeader<'_>>,
    content_type_header: ContentTypeHeader<'_>,
    filename_header: FilenameHeader<'_>,
) -> Result<String, Status> {
    log::info!("add_media");
    let user = get_media_user(None, auth_header, cookies, state)?;
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
            content_type: content_type_header.0.to_string(),
            name: Some(filename_header.0.to_string()),
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
    auth_header: Option<AuthHeader<'_>>,
) -> Result<NamedFile, Status> {
    log::info!("media_file: {:?}", id);
    let _user = get_media_user(jonline_access_token, auth_header, cookies, state).ok();

    let media = schema::media::table
        .filter(
            media::id.eq(id
                .to_string()
                .to_db_big_id_or_err("media_id")
                .map_err(|_| Status::BadRequest)?),
        )
        .first::<models::Media>(&mut state.pool.get().unwrap())
        .map_err(|_| Status::NotFound)?;

    // TODO: Validate moderation/visiblity/permissions etc.

    let local_filename = format!(
        "{}/{}.mediafile",
        state.tempdir.path().display(),
        media.minio_path
    );
    if !std::path::Path::new(&local_filename).exists() {
        info!("local_filename: {}", local_filename);

        // Ensure local directory exists.
        let mut _filevec: Vec<&str> = local_filename.split("/").collect();
        _filevec.pop();
        let local_filedir = _filevec.join("/");
        info!("local_filedir: {}", local_filedir);
        std::fs::create_dir_all(local_filedir).map_err(|_| Status::InternalServerError)?;

        // Download file from S3 into a tempfile
        let temp_filename = format!("{}.{}", local_filename, Uuid::new_v4());
        let mut async_output_file = tokio::fs::File::create(temp_filename.to_owned())
            .await
            .map_err(|_| Status::InternalServerError)?;
        let _status_code = state
            .bucket
            .get_object_to_writer(media.minio_path, &mut async_output_file)
            .await
            .map_err(|_| Status::InternalServerError)?;

        // Rename tempfile to final filename
        std::fs::rename(temp_filename, &local_filename).map_err(|_| Status::InternalServerError)?
    }

    let result = NamedFile::open(local_filename)
        .await
        .map_err(|_| Status::InternalServerError)?;
    Ok(result)

    // let mut _stream = state
    //     .bucket
    //     .get_object_stream(media.minio_path.as_str())
    //     .await
    //     .map_err(|_| Status::NotFound)?;

    // Ok(ByteStream::from(async_output_file.st))

    // This should work.
    // Ok(ByteStream::from(_stream.bytes()))

    // Or this.
    // Ok(ByteStream! {
    //     let mut stream: &'a ResponseDataStream = &state
    //         .bucket
    //         .get_object_stream(media.minio_path.as_str())
    //         .await
    //         .map_err(|_| Status::NotFound).unwrap();
    //     while let Some(bytes) = stream.bytes().next().await {
    //         yield bytes;
    //     }
    // })

    // We should at least be able to write to an output file and return that... but this doesn't compile either.
    // Seems the S3 `ResponseDataStream` type is not `Send`.

    // let mut async_output_file = tokio::fs::File::create(media.minio_path).await.expect("Unable to create file");
    // while let Some(chunk) = _stream.bytes.next().await {
    //     async_output_file.write_all(&chunk).await.map_err(|_| Status::NotFound)?;
    // }

    // So far all I can get to work is this...
    // Ok(ByteStream! { yield bytes::Bytes::from("test")})
}

/// Gets the user from a manual jonline_access_token, auth header, or cookies (in that priority order).
fn get_media_user(
    jonline_access_token: Option<String>,
    auth_header: Option<AuthHeader<'_>>,
    cookies: &CookieJar<'_>,
    state: &State<RocketState>,
) -> Result<models::User, Status> {
    let access_token = match jonline_access_token {
        Some(access_token) => access_token,
        None => match auth_header {
            Some(auth_header) => auth_header.0.to_string(),
            None => match cookies.get("jonline_access_token") {
                Some(access_token) => access_token.value().to_string(),
                None => return Err(Status::Unauthorized),
            },
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
