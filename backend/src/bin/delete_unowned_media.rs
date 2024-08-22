extern crate diesel;
extern crate jonline;
use diesel::*;
use jonline::{db_connection, minio_connection, init_bin_logging};
use jonline::schema::{media, posts};

#[tokio::main]
async fn main() {
    init_crypto();
    init_bin_logging();
    log::info!("Deleting Unowned Media...");
    log::info!("Connecting to DB and MinIO...");
    let mut conn = db_connection::establish_connection();
    let bucket = minio_connection::get_and_test_bucket().await.expect("Failed to connect to MinIO");

    let mut unowned_media = media::table
        .filter(media::user_id.is_null()).load::<jonline::models::Media>(&mut conn)
        .expect("Failed to load Unowned Media");

    for media in unowned_media.iter_mut() {
        log::info!("Deleting Media: {:?}", media);
        let posts = posts::table
            .filter(posts::media.contains(vec![media.id]))
            .load::<jonline::models::Post>(&mut conn)
            .expect("Failed to load Posts with Media");
        for post in posts {
            log::info!("Removing Media {} from Post {}", media.id, post.id);
            let mut post_media = post.media.clone();
            post_media.retain(|&x| x != media.id);
            let _ = diesel::update(posts::table.find(post.id))
                .set(posts::media.eq(post_media))
                .execute(&mut conn)
                .expect("Failed to update Post");
        }

        match bucket.delete_object(&media.minio_path).await {
            Ok(_) => { 
                delete(media::table.find(media.id)).execute(&mut conn)
                    .expect("Failed to delete Media");
                log::info!("Deleted Media: {:?}", media);
             },
            Err(e) => log::error!("Failed to delete Media: {:?} with error: {:?}. Proceeding through remaining media.", media, e),
        }
    }
    log::info!("Done Deleting Unowned Media.");
}
