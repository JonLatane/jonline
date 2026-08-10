use diesel::NotFound;
use diesel::*;
use s3::Bucket;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::ConvertedSizeSpec;
use crate::protos::*;
use crate::schema::media;

use crate::rpcs::validations::*;

pub async fn delete_media(
    request: Media,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
    bucket: &Bucket,
) -> Result<(), Status> {
    let media_id = request.id.to_db_id_or_err("id")?;
    let affected_media = media::table
        .filter(media::id.eq(media_id))
        .get_result::<models::Media>(conn)
        .optional()
        .map_err(|e| {
            log::error!("Error finding media: {:?}", e);
            Status::new(Code::Internal, "media_not_found")
        })?;

    let affected_media = match affected_media {
        Some(affected_media) => affected_media,
        None => return Err(Status::new(Code::NotFound, "media_not_found")),
    };

    let self_delete = affected_media.user_id == Some(current_user.id);
    let mut admin = false;
    if !self_delete {
        validate_any_permission(&Some(current_user), vec![Permission::Admin])?;
    }
    match validate_permission(&Some(current_user), Permission::Admin) {
        Ok(_) => admin = true,
        Err(_) => {}
    };
    log::info!("self_delete: {}, admin: {}", self_delete, admin);

    if !(self_delete | admin) {
        return Err(Status::new(Code::PermissionDenied, "not_your_media"));
    }

    // Collect every MinIO object backing this Media -- the original upload plus any
    // small/medium/large converted copies -- before the row (and its `converted_sizes`) is gone.
    let mut minio_paths = vec![affected_media.minio_path.clone()];
    let converted_sizes = affected_media.converted_sizes();
    for spec in ConvertedSizeSpec::ALL {
        if let Some(converted) = converted_sizes.get(spec) {
            minio_paths.push(converted.minio_path.clone());
        }
    }

    let db_result = delete(media::table.find(media_id)).execute(conn);

    let result = match db_result {
        Ok(size) if size == 0 => Err(Status::new(Code::NotFound, "media_not_found")),
        Ok(_) => Ok(()),
        Err(NotFound) => Err(Status::new(Code::NotFound, "media_not_found")),
        Err(e) => {
            log::error!("Error deleting media: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    };

    if result.is_ok() {
        for minio_path in minio_paths {
            if let Err(e) = bucket.delete_object(&minio_path).await {
                log::error!(
                    "Failed to delete MinIO object {} for media {}: {:?}",
                    minio_path,
                    media_id,
                    e
                );
            }
        }
    }

    log::info!("DeleteMedia::request: {:?}, result: {:?}", request, result);

    result
}
