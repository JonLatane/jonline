extern crate anyhow;
extern crate diesel;
extern crate jonline;

use diesel::*;
use headless_chrome::protocol::cdp::Page::CaptureScreenshotFormatOption::Png;
use headless_chrome::{protocol::cdp::Target::CreateTarget, Browser};

use jonline::db_connection;
use jonline::schema::posts::dsl::*;
use jonline::conversions::ToLink;

pub fn main() {
    println!("Generating preview images...");
    println!("Connecting to DB...");
    let conn = db_connection::establish_connection();
    let posts_to_update = posts
        .filter(preview.is_null())
        .filter(link.is_not_null())
        .limit(100)
        .load::<jonline::models::Post>(&conn)
        .unwrap();
    println!("Got {} posts to update.", posts_to_update.len());

    for post in posts_to_update {
        println!("Generating preview image for post: {}", post.id);
        match post.link.to_link() {
            None => println!("Invalid link: {:?}", post.link),
            Some(url) => {
                match generate_preview(&url) {
                    Ok(screenshot) => {
                        println!(
                            "Generated screenshot for link {}, post {}! {} bytes",
                            url,
                            post.id,
                            screenshot.len()
                        );
                        update(posts)
                            .filter(id.eq(post.id))
                            .set(preview.eq(screenshot))
                            .execute(&crate::db_connection::establish_connection())
                            .unwrap();
                    }
                    Err(e) => {
                        println!("Failed to generate screenshot for link {}: {}", url, e);
                    }
                };
            }
        }
    };

    println!("Done generating preview images.");
}

fn generate_preview(url: &str) -> Result<Vec<u8>, anyhow::Error> {
    let options = headless_chrome::LaunchOptionsBuilder::default()
        .sandbox(false)
        .args(
            [
                std::ffi::OsStr::new("--hide-scrollbars"),
                std::ffi::OsStr::new("--lang=en_US"),
                std::ffi::OsStr::new("--headless=chrome"),
            ]
            .to_vec(),
        )
        .extensions(
            [
                std::ffi::OsStr::new("/opt/ublock"),
                std::ffi::OsStr::new("/opt/nocookies"),
            ]
            .to_vec(),
        )
        .window_size(Some((400, 400)))
        .build()
        .unwrap();
    let browser = Browser::new(options)?;
    let tab = browser.new_tab_with_options(CreateTarget {
        url: url.to_string(),
        background: Some(true),
        new_window: Some(true),
        width: Some(400),
        height: Some(400),
        browser_context_id: None,
        enable_begin_frame_control: None,
    })?;
    tab.navigate_to(&url)?;
    tab.wait_until_navigated()?;
    return Ok(tab.capture_screenshot(Png, None, None, false)?);
}
