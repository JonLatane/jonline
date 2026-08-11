use std::env;

use awscreds::Credentials;
// use awsregion::Region;
use s3::error::S3Error;
use s3::Region;
use s3::{Bucket, BucketConfiguration};

pub async fn get_and_test_bucket() -> Result<Box<Bucket>, S3Error> {
    let minio_access_key = env::var("MINIO_ACCESS_KEY").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_ACCESS_KEY".to_string(),
            "".to_string(),
        ))
    })?;
    let minio_secret_key = env::var("MINIO_SECRET_KEY").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_SECRET_KEY".to_string(),
            "".to_string(),
        ))
    })?;

    let bucket = get_bucket()?;

    let s3_path = "test.file";
    let test = b"I'm going to S3!";

    // `Bucket` is just a config struct (name/region/credentials), not a live connection, so
    // it doesn't need to be reconstructed after creating the bucket below -- the same `bucket`
    // can be reused for the retried `put_object`.
    let response_data = match bucket.put_object(s3_path, test).await {
        Err(e) if e.to_string().contains("NoSuchBucket") => {
            log::warn!("MinIO bucket does not exist, attempting to create");
            Bucket::create_with_path_style(
                bucket.name.as_str(),
                bucket.region.clone(),
                Credentials {
                    access_key: Some(minio_access_key.to_owned()),
                    secret_key: Some(minio_secret_key.to_owned()),
                    security_token: None,
                    expiration: None,
                    session_token: None,
                },
                BucketConfiguration::public(),
            )
            .await
            .map_err(|e| {
                log::error!("Failed to create MinIO Bucket: {:?}", e);
                e
            })?;
            log::warn!("MinIO bucket created");
            bucket.put_object(s3_path, test).await
        }
        other => other,
    };
    assert_eq!(response_data?.status_code(), 200);

    let response_data = bucket.get_object(s3_path).await?;
    assert_eq!(response_data.status_code(), 200);
    assert_eq!(test, response_data.as_slice());

    let (head_object_result, code) = bucket.head_object(s3_path).await?;
    assert_eq!(code, 200);
    assert_eq!(
        head_object_result.content_type.unwrap_or_default(),
        "application/octet-stream".to_owned()
    );

    let response_data = bucket.delete_object(s3_path).await?;
    assert_eq!(response_data.status_code(), 204);
    Ok(bucket)
}

fn get_bucket() -> Result<Box<Bucket>, S3Error> {
    let minio_endpoint = env::var("MINIO_ENDPOINT").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_ENDPOINT".to_string(),
            "".to_string(),
        ))
    })?;
    let minio_region = env::var("MINIO_REGION").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_REGION".to_string(),
            "".to_string(),
        ))
    })?;
    let minio_bucket = env::var("MINIO_BUCKET").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_BUCKET".to_string(),
            "".to_string(),
        ))
    })?;
    let minio_access_key = env::var("MINIO_ACCESS_KEY").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_ACCESS_KEY".to_string(),
            "".to_string(),
        ))
    })?;
    let minio_secret_key = env::var("MINIO_SECRET_KEY").map_err(|_| {
        S3Error::Credentials(awscreds::error::CredentialsError::MissingEnvVar(
            "MINIO_SECRET_KEY".to_string(),
            "".to_string(),
        ))
    })?;
    Ok(Bucket::new(
        &minio_bucket,
        Region::Custom {
            region: minio_region.to_owned(),
            endpoint: minio_endpoint.to_owned(),
        },
        Credentials {
            access_key: Some(minio_access_key.to_owned()),
            secret_key: Some(minio_secret_key.to_owned()),
            security_token: None,
            expiration: None,
            session_token: None,
        },
    )?
    .with_path_style())
}
