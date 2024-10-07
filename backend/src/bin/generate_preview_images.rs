extern crate anyhow;
extern crate diesel;
extern crate jonline;

use std::path::PathBuf;
use std::thread;
use std::time::Duration;

use diesel::*;
use headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::*;
use headless_chrome::{protocol::cdp::Target::CreateTarget, Browser};

use jonline::db_connection::PgPooledConnection;
use jonline::models;
use jonline::models::{get_user, Post};
use jonline::protos::Visibility;
use jonline::schema::{media, posts};
use jonline::{db_connection, init_bin_logging, minio_connection};
use jonline::{init_crypto, marshaling::*};
use s3::Bucket;
use uuid::Uuid;

#[tokio::main]
async fn main() {
    init_crypto();
    init_bin_logging();
    log::info!("Generating preview images...");
    log::info!("Connecting to DB and MinIO...");
    let pool = db_connection::establish_pool();
    let mut conn = pool.get().expect("Failed to get DB connection");
    let bucket = minio_connection::get_and_test_bucket()
        .await
        .expect("Failed to connect to MinIO");

    log::info!("Starting browser...");
    let browser = start_browser().expect("Failed to start browser");

    let posts_to_update = posts::table
        .filter(posts::link.is_not_null())
        .filter(posts::media_generated.eq(false))
        .limit(100)
        .load::<Post>(&mut conn)
        .unwrap();
    log::info!("Got {} posts to update.", posts_to_update.len());

    for post in posts_to_update {
        update_post(&post, &browser, &mut conn, &bucket).await;
    }

    log::info!("Done generating preview images.");
}

async fn update_post(
    post: &Post,
    browser: &Browser,
    conn: &mut PgPooledConnection,
    bucket: &Bucket,
) {
    if post.user_id.is_none() {
        log::warn!("Post {} has no user_id, skipping.", post.id);
        return;
    }
    log::info!("Generating preview image for post: {}", post.id);
    let user = get_user(post.user_id.unwrap(), conn).unwrap();
    match post.link.to_link() {
        None => log::warn!("Invalid link: {:?}", post.link),
        Some(url) => {
            match generate_preview(&url, &browser) {
                Ok(screenshot) => {
                    log::info!(
                        "Generated screenshot for link {}, post {}! {} bytes",
                        url,
                        post.id,
                        screenshot.len()
                    );

                    let filename = format!("post_{}_generated_preview.png", post.id.to_proto_id());
                    let uuid = Uuid::new_v4();
                    let minio_path = format!(
                        "user/{}-{}/{}-{}",
                        user.id.to_proto_id(),
                        user.username,
                        uuid,
                        filename
                    );
                    let upload_status = bucket
                        .put_object(&minio_path, screenshot.as_slice())
                        .await
                        .map_err(|e| {
                            log::warn!("Failed to upload screenshot for link {}: {}", url, e);
                            return;
                        });

                    log::info!("generate_preview_images upload_status: {:?}", upload_status);

                    let media = insert_into(media::table)
                        .values(&models::NewMedia {
                            user_id: post.user_id,
                            minio_path,
                            content_type: "image/png".to_string(),
                            name: Some(filename.to_string()),
                            description: None,
                            generated: true,
                            visibility: Visibility::GlobalPublic.to_string_visibility(),
                        })
                        .get_result::<models::Media>(conn)
                        .unwrap();

                    let mut new_media = vec![Some(media.id)];
                    new_media.append(&mut post.media.clone());
                    update(posts::table)
                        .filter(posts::id.eq(post.id))
                        .set((posts::media.eq(new_media), posts::media_generated.eq(true)))
                        .execute(conn)
                        .unwrap();
                }
                Err(e) => {
                    log::error!("Failed to generate screenshot for link {}: {}", url, e);
                }
            };
        }
    }
}

fn generate_preview(url: &str, browser: &Browser) -> Result<Vec<u8>, anyhow::Error> {
    let tab = browser.new_tab_with_options(CreateTarget {
        url: url.to_string(),
        background: Some(true),
        new_window: Some(true),
        width: Some(640),
        height: Some(640),
        browser_context_id: None,
        enable_begin_frame_control: None,
    })?;
    tab.navigate_to(&url)?;
    tab.wait_until_navigated()?;
    // Allow time for client-side page rendering and extensions to work.
    thread::sleep(Duration::from_secs(10));
    let result = tab.capture_screenshot(Png, None, None, false)?;
    tab.close(true)?;
    return Ok(result);
}

fn start_browser() -> Result<Browser, anyhow::Error> {
    let options = headless_chrome::LaunchOptionsBuilder::default()
        .path(Some(PathBuf::from("/usr/bin/brave-browser")))
        .headless(false)
        .disable_default_args(true)
        .sandbox(false)
        .args(
            [
                std::ffi::OsStr::new("--headless=chrome"),
                std::ffi::OsStr::new("--hide-scrollbars"),
                std::ffi::OsStr::new("--lang=en_US"),
                // Default args but with extensions enabled
                std::ffi::OsStr::new("--disable-background-networking"),
                std::ffi::OsStr::new("--enable-features=NetworkService,NetworkServiceInProcess"),
                std::ffi::OsStr::new("--disable-background-timer-throttling"),
                std::ffi::OsStr::new("--disable-backgrounding-occluded-windows"),
                std::ffi::OsStr::new("--disable-breakpad"),
                std::ffi::OsStr::new("--disable-client-side-phishing-detection"),
                // std::ffi::OsStr::new("--disable-component-extensions-with-background-pages"),
                std::ffi::OsStr::new("--disable-default-apps"),
                std::ffi::OsStr::new("--disable-dev-shm-usage"),
                //    std::ffi::OsStr::new( "--disable-extensions"),
                // BlinkGenPropertyTrees disabled due to crbug.com/937609
                std::ffi::OsStr::new("--disable-features=TranslateUI,BlinkGenPropertyTrees"),
                std::ffi::OsStr::new("--disable-hang-monitor"),
                std::ffi::OsStr::new("--disable-ipc-flooding-protection"),
                // std::ffi::OsStr::new("--disable-popup-blocking"),
                std::ffi::OsStr::new("--disable-prompt-on-repost"),
                std::ffi::OsStr::new("--disable-renderer-backgrounding"),
                std::ffi::OsStr::new("--disable-sync"),
                std::ffi::OsStr::new("--force-color-profile=srgb"),
                std::ffi::OsStr::new("--metrics-recording-only"),
                std::ffi::OsStr::new("--no-first-run"),
                std::ffi::OsStr::new("--enable-automation"),
                std::ffi::OsStr::new("--password-store=basic"),
                std::ffi::OsStr::new("--use-mock-keychain"),
            ]
            .to_vec(),
        )
        .extensions(
            [
                std::ffi::OsStr::new("/opt/preview_generator_extensions/ublock/"),
                std::ffi::OsStr::new("/opt/preview_generator_extensions/nocookies/"),
            ]
            .to_vec(),
        )
        .window_size(Some((640, 640)))
        .build()
        .unwrap();
    Ok(Browser::new(options)?)
    // Browser::connect("ws://0.0.0.0:9222".to_string())
}
