use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::{post_post, PostFacebookContent};
use crate::marshaling::*;
use crate::models;
use crate::models::POST_COLUMNS;
use crate::protos::*;
use crate::rpcs::{get_server_configuration_proto, validate_permission};
use crate::schema::{post_sync_destinations, posts};

pub fn sync_post(
    request: SyncPostRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Post, Status> {
    validate_permission(&Some(current_user), Permission::SyncPostsToFacebook)?;

    let post_id = request.post_id.to_db_id_or_err("post_id")?;
    let destination_id = request
        .sync_destination_id
        .to_db_id_or_err("sync_destination_id")?;

    let post: models::Post = posts::table
        .select(POST_COLUMNS)
        .filter(posts::id.eq(post_id))
        .first(conn)
        .map_err(|_| Status::new(Code::NotFound, "post_not_found"))?;

    let destination = models::get_sync_destination(destination_id, conn)?;
    if destination.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    // Only buildable when this server has `external_cdn_config.frontend_host` configured -- this
    // RPC has no HTTP `Host` header to fall back on the way web-facing routes
    // (`configured_frontend_domain`) do, so the link is simply omitted otherwise. See
    // `docs/facebook_federation.md`.
    let frontend_host = get_server_configuration_proto(conn)?
        .external_cdn_config
        .map(|c| c.frontend_host)
        .filter(|h| !h.trim().is_empty());
    let post_url =
        frontend_host.map(|host| format!("https://{host}/post/{}", post.id.to_proto_id()));

    let (destination_instance_id, destination_url) = post_post(
        &destination,
        &PostFacebookContent {
            title: &post.title,
            content: &post.content,
            link: &post.link,
            post_url: &post_url,
        },
    )?;

    let new_row = models::NewPostSyncDestination {
        post_id: post.id,
        sync_destination_id: destination.id,
        destination_instance_id: Some(destination_instance_id),
        destination_url: Some(destination_url),
        synced_at: Some(SystemTime::now()),
    };
    insert_into(post_sync_destinations::table)
        .values(&new_row)
        .on_conflict((
            post_sync_destinations::post_id,
            post_sync_destinations::sync_destination_id,
        ))
        .do_update()
        .set(&new_row)
        .execute(conn)
        .map_err(|e| {
            log::error!("Failed to record post sync status: {:?}", e);
            Status::new(Code::Internal, "failed_to_record_post_sync")
        })?;

    let posts = crate::rpcs::get_posts(
        GetPostsRequest {
            post_id: Some(post.id.to_proto_id()),
            ..Default::default()
        },
        &Some(current_user),
        conn,
    )?
    .posts;
    posts
        .into_iter()
        .find(|p| p.id == post.id.to_proto_id())
        .ok_or_else(|| Status::new(Code::Internal, "failed_to_reload_synced_post"))
}
