use std::time::SystemTime;

use diesel::result::Error::RollbackTransaction;
use diesel::NotFound;
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs;
use crate::schema::posts;
// use crate::schema::users;

use super::validations::*;

pub fn update_post(
    request: Post,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Post, Status> {
    // validate_user(&request)?;
    // validate_post(&request)?;

    let mut admin = false;
    let mut moderator = false;
    match validate_permission(&current_user, Permission::Admin) {
        Ok(_) => admin = true,
        Err(_) => {}
    };
    match validate_permission(&current_user, Permission::ModeratePosts) {
        Ok(_) => moderator = true,
        Err(_) => {}
    };

    let mut existing_post = posts::table
        .select(posts::all_columns)
        .filter(posts::id.eq(request.id.to_db_id().unwrap()))
        .first::<models::Post>(conn)
        .map_err(|_| Status::new(Code::NotFound, "post_not_found"))?;

    let self_update = existing_post.user_id == Some(current_user.id);
    log::info!(
        "self_update: {}, admin: {}, moderator: {}",
        self_update,
        admin,
        moderator
    );

    if !self_update {
        validate_any_permission(
            &current_user,
            vec![Permission::Admin, Permission::ModeratePosts],
        )?;
    }
    let transaction_result: Result<models::Post, diesel::result::Error> = conn
        .transaction::<models::Post, diesel::result::Error, _>(|conn| {
            if admin || self_update {
                // Only Events/EventInstances support title updates.
                if vec![PostContext::Event, PostContext::EventInstance]
                    .iter()
                    .map(|c| c.to_string_post_context())
                    .any(|s| s == existing_post.context)
                {
                    existing_post.title = request.title.to_owned();
                }
                existing_post.content = request.content.to_owned();
                existing_post.media = request
                    .media
                    .iter()
                    .map(|m| m.id.to_db_id_or_err("media.id"))
                    .collect::<Result<Vec<i64>, Status>>()
                    .map_err(|_| diesel::result::Error::RollbackTransaction)?;
                existing_post.embed_link = request.embed_link;
                existing_post.shareable = request.shareable;
                existing_post.updated_at = SystemTime::now().into();
                // existing_post.username = request.username.to_owned();
                // existing_post.bio = request.bio.to_owned();
                // existing_post.avatar_media_id = request.avatar.as_ref().map(|a| &a.id).to_db_opt_id().unwrap();
                // if request.visibility == Visibility::GlobalPublic as i32
                //     && existing_post.visibility.to_proto_visibility().unwrap()
                //         != Visibility::GlobalPublic
                // {
                //     validate_permission(&current_user, Permission::PublishUsersGlobally)
                //         .map_err(|_| RollbackTransaction)?;
                // }
                // existing_post.visibility = request.visibility.to_string_visibility();
                // existing_post.default_follow_moderation = request.default_follow_moderation.to_string_moderation();
            }
            if admin || moderator {
                existing_post.moderation = request.moderation.to_string_moderation();
                // existing_post.permissions = request.permissions.to_json_permissions();
            }
            existing_post.updated_at = SystemTime::now().into();

            log::info!("Updating post: {:?}", existing_post);
            match diesel::update(posts::table)
                .filter(posts::id.eq(&existing_post.id))
                .set(&existing_post)
                .execute(conn)
            {
                Ok(_) => Ok(existing_post),
                Err(e) => Err(e),
            }
        });

    let result = match transaction_result {
        //TODO: properly marshal this stuff
        Ok(_post) => {
            rpcs::get_posts(
                GetPostsRequest {
                    post_id: Some(request.id.clone()),
                    ..Default::default()
                },
                &Some(current_user),
                conn,
            )
            .map(|u| u.posts[0].to_owned())
            // Ok(result.to_proto(&None, &None, None))
        }
        Err(NotFound) => Err(Status::new(Code::NotFound, "user_not_found")),
        Err(RollbackTransaction) => Err(Status::new(
            Code::InvalidArgument,
            "cannot_publish_globally",
        )),
        Err(e) => {
            log::error!("Error updating user: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    };
    log::info!("UpdatePost::request: {:?}, result: {:?}", &request, result);

    result
}
