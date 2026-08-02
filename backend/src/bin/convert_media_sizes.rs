extern crate diesel;
extern crate jonline;

use jonline::logic::{convert_media, media_pending_conversion, FFmpeg, ImageMagick};
use jonline::{db_connection, init_bin_logging, init_crypto, minio_connection};

/// Processes Media in batches of this size per run -- background_jobs.sh re-invokes this binary
/// on an interval, so a large backlog just gets worked down over several runs rather than one
/// long-running process.
const BATCH_SIZE: i64 = 20;

#[tokio::main]
async fn main() {
    init_crypto();
    init_bin_logging();
    log::info!("Converting Media sizes...");

    let imagemagick = ImageMagick::detect();
    if imagemagick.is_none() {
        log::error!(
            "ImageMagick not found on $PATH (tried 'magick', and 'convert'+'identify'). \
             Install it to enable automatic image size conversion; skipping images this run."
        );
    }
    let ffmpeg = FFmpeg::detect();
    if ffmpeg.is_none() {
        log::error!(
            "ffmpeg not found on $PATH (tried 'ffmpeg' and 'ffprobe'). \
             Install it to enable automatic video size conversion; skipping videos this run."
        );
    }
    if imagemagick.is_none() && ffmpeg.is_none() {
        log::error!("Neither ImageMagick nor ffmpeg found on $PATH; skipping this run entirely.");
        std::process::exit(1);
    }

    log::info!("Connecting to DB and MinIO...");
    let pool = db_connection::establish_pool();
    let mut conn = pool.get().expect("Failed to get DB connection");
    let bucket = minio_connection::get_and_test_bucket()
        .await
        .expect("Failed to connect to MinIO");

    let pending = media_pending_conversion(&mut conn, BATCH_SIZE)
        .expect("Failed to load Media pending conversion");
    log::info!("Got {} Media item(s) to convert.", pending.len());

    let tmp_dir = tempfile::tempdir().expect("Failed to create temp dir");

    for item in pending.iter() {
        log::info!("Converting Media {}: {}", item.id, item.minio_path);
        match convert_media(
            item,
            imagemagick.as_ref(),
            ffmpeg.as_ref(),
            &bucket,
            tmp_dir.path(),
            &mut conn,
        )
        .await
        {
            Ok(_) => log::info!("Converted Media {}.", item.id),
            Err(e) => log::error!("Failed to convert Media {}: {:?}", item.id, e),
        }
    }

    log::info!("Done converting Media sizes.");
}
