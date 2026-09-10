extern crate anyhow;
extern crate diesel;
extern crate rellm;

use std::path::PathBuf;
use std::sync::Arc;
use std::thread;
use std::time::Duration;

use diesel::*;
use headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::*;
use headless_chrome::{protocol::cdp::Target::CreateTarget, Browser};
use tokio::task::spawn_blocking;
use tokio::time::timeout;

use rellm::db_connection::PgPooledConnection;
use rellm::models;
use rellm::models::{get_user, Post, POST_COLUMNS};
use rellm::protos::rellm_client::RellmClient;
use rellm::protos::{
    ClusterResource, ClusterResources, FreeClusterResourcesRequest, LockClusterResourcesRequest,
    Visibility,
};
use rellm::schema::{media, posts};
use rellm::{db_connection, init_bin_logging, minio_connection, rpcs};
use rellm::{init_crypto, marshaling::*};
use s3::Bucket;
use tonic::transport::Channel;
use uuid::Uuid;

#[tokio::main]
async fn main() {
    init_crypto();
    init_bin_logging();
    log::info!("Generating preview images...");
    log::info!("Connecting to DB...");
    let pool = db_connection::establish_pool();
    let mut conn = pool.get().expect("Failed to get DB connection");

    let posts_to_update = posts::table
        .filter(posts::link.is_not_null())
        .filter(posts::media_generated.eq(false))
        .select(POST_COLUMNS)
        .limit(100)
        .load::<Post>(&mut conn)
        .unwrap();
    log::info!("Got {} posts to update.", posts_to_update.len());

    if posts_to_update.is_empty() {
        log::info!("No posts to update, exiting.");
        return;
    }

    log::info!("Connecting to MinIO...");
    let bucket = minio_connection::get_and_test_bucket()
        .await
        .expect("Failed to connect to MinIO");

    // If this server is part of a cluster (see `ClusterResources`'s own doc in
    // server_configuration.proto), only one instance may have a browser open at a time --
    // acquire that lock from the conductor before launching Chrome/Brave below. Servers not
    // configured with `cluster_resources` skip this entirely (single-instance mode, unchanged
    // from before this existed).
    let cluster_resources: Option<ClusterResources> = rpcs::get_server_configuration_model(&mut conn)
        .expect("Failed to load server configuration")
        .cluster_resources
        .and_then(|v| serde_json::from_value(v).ok());

    if let Some(resources) = &cluster_resources {
        log::info!("Cluster resources configured; acquiring browser lock from conductor...");
        if !acquire_browser_lock(resources).await {
            log::warn!("Could not acquire cluster browser lock in time; skipping this run.");
            return;
        }
    }

    log::info!("Starting browser...");
    let browser = Arc::new(start_browser().expect("Failed to start browser"));

    for post in posts_to_update {
        update_post(&post, &browser, &mut conn, &bucket).await;
    }

    if let Some(resources) = &cluster_resources {
        release_browser_lock(resources).await;
    }

    log::info!("Done generating preview images.");
}

const LOCK_POLL_INTERVAL: Duration = Duration::from_secs(5);
const LOCK_MAX_WAIT: Duration = Duration::from_secs(180);

/// Polls `LockClusterResources` on the conductor until it grants the browser lock to this
/// instance or `LOCK_MAX_WAIT` elapses (returning `false` in the latter case -- there's no
/// server-side queueing, see `LockClusterResourcesResponse`'s own doc). Also backs off and
/// retries on a connection/RPC error (e.g. the conductor briefly unreachable), rather than
/// failing the whole job over a transient network blip.
async fn acquire_browser_lock(resources: &ClusterResources) -> bool {
    let deadline = tokio::time::Instant::now() + LOCK_MAX_WAIT;
    loop {
        match try_lock_browser(resources).await {
            Ok(true) => return true,
            Ok(false) => log::info!("Browser lock held by another namespace; waiting..."),
            Err(e) => log::warn!("Error calling LockClusterResources: {:?}", e),
        }
        if tokio::time::Instant::now() >= deadline {
            return false;
        }
        tokio::time::sleep(LOCK_POLL_INTERVAL).await;
    }
}

async fn try_lock_browser(resources: &ClusterResources) -> Result<bool, anyhow::Error> {
    let mut client = cluster_client(resources).await?;
    let mut request = tonic::Request::new(LockClusterResourcesRequest {
        namespace_id: resources.namespace_id.clone(),
        resources: vec![ClusterResource::Browser as i32],
    });
    request
        .metadata_mut()
        .insert("cluster-shared-secret", resources.cluster_shared_secret.parse()?);
    let response = client.lock_cluster_resources(request).await?.into_inner();
    Ok(response.granted)
}

/// Best-effort: logs and gives up on error rather than panicking -- the Job's container exiting
/// (see `generate_preview_with_timeout`'s own doc) doesn't clear a lock recorded in the
/// conductor's database the way it would an in-memory one, so a failed release here does leak
/// the lock until manually cleared. Not retried; a transient failure here is rare enough (this
/// runs right after a successful `LockClusterResources` call to the same conductor) not to be
/// worth another poll loop.
async fn release_browser_lock(resources: &ClusterResources) {
    let result: Result<(), anyhow::Error> = async {
        let mut client = cluster_client(resources).await?;
        let mut request = tonic::Request::new(FreeClusterResourcesRequest {
            namespace_id: resources.namespace_id.clone(),
            resources: vec![ClusterResource::Browser as i32],
        });
        request
            .metadata_mut()
            .insert("cluster-shared-secret", resources.cluster_shared_secret.parse()?);
        client.free_cluster_resources(request).await?;
        Ok(())
    }
    .await;
    if let Err(e) = result {
        log::error!(
            "Error calling FreeClusterResources (browser lock may be stuck held): {:?}",
            e
        );
    }
}

/// Connects to `resources.conductor_host` on the standard Rellm gRPC port, first resolving it
/// through the usual [`GET /backend_host`](#http-based-client-host-negotiation-for-external-cdns-get-backend_host)
/// negotiation (see `ClusterResources.conductor_host`'s own doc) in case it sits behind an
/// external CDN.
async fn cluster_client(resources: &ClusterResources) -> Result<RellmClient<Channel>, anyhow::Error> {
    let host = discover_backend_host(&resources.conductor_host).await;
    let channel = Channel::from_shared(format!("https://{host}:27707"))?
        .timeout(Duration::from_secs(10))
        .connect()
        .await?;
    Ok(RellmClient::new(channel))
}

async fn discover_backend_host(host: &str) -> String {
    let host = host.to_string();
    let lookup = move || {
        let client = reqwest::blocking::Client::builder()
            .timeout(Duration::from_secs(5))
            .build()
            .unwrap();
        for scheme in ["https", "http"] {
            if let Ok(response) = client.get(format!("{scheme}://{host}/backend_host")).send() {
                if response.status().is_success() {
                    if let Ok(body) = response.text() {
                        let body = body.trim();
                        if !body.is_empty() {
                            return body.to_string();
                        }
                    }
                }
            }
        }
        host
    };
    // `reqwest::blocking` panics if called directly from a Tokio worker thread -- `main` is
    // `#[tokio::main]`, so route it through `block_in_place` the same way
    // `logic::http_client::run_blocking` does for in-process (non-`bin/`) callers.
    tokio::task::block_in_place(lookup)
}

const PREVIEW_TIMEOUT: Duration = Duration::from_secs(45);

async fn update_post(
    post: &Post,
    browser: &Arc<Browser>,
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
            match generate_preview_with_timeout(url.clone(), Arc::clone(browser)).await {
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
                            metadata: serde_json::to_value(models::MediaMetadata::default())
                                .unwrap(),
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

// Runs generate_preview (which blocks on Chrome IPC and a fixed render-wait sleep) on a
// blocking-pool thread with a hard wall-clock cap, so one slow/unresponsive link can't
// wedge the whole job. A timed-out call is left running on its thread rather than killed;
// it's harmless since the Job's container is torn down (killing the browser process with
// it) once main() returns.
async fn generate_preview_with_timeout(
    url: String,
    browser: Arc<Browser>,
) -> Result<Vec<u8>, anyhow::Error> {
    match timeout(
        PREVIEW_TIMEOUT,
        spawn_blocking(move || generate_preview(&url, &browser)),
    )
    .await
    {
        Ok(join_result) => join_result.unwrap_or_else(|e| Err(anyhow::anyhow!(e))),
        Err(_) => Err(anyhow::anyhow!(
            "Timed out generating preview after {:?}",
            PREVIEW_TIMEOUT
        )),
    }
}

fn generate_preview(url: &str, browser: &Browser) -> Result<Vec<u8>, anyhow::Error> {
    let tab = browser.new_tab_with_options(CreateTarget {
        url: url.to_string(),
        background: Some(true),
        new_window: Some(true),
        width: Some(1080),
        height: Some(1080),
        left: None,
        top: None,
        window_state: None,
        browser_context_id: None,
        enable_begin_frame_control: None,
        for_tab: None,
        hidden: None,
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
