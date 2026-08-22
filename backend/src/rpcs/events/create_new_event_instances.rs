use diesel::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::{event_instances, posts};

use super::event_permissions::{find_existing_instance, validate_event_edit_permission};

/// Creates an `EventInstance` for every entry in `instances` that isn't already on `event` (i.e.
/// whose `id` doesn't parse, or doesn't belong to this event); entries that do match are left
/// untouched (see `update_event_instances` for updating those in place). Returns `instances` with
/// each created entry's `id` replaced by its newly-minted database id -- callers that need to know
/// which instances survive this event (like `update_event`, feeding `delete_removed_event_instances`)
/// can't otherwise tell a request instance just created apart from one about to be deleted, since
/// both have no id the deletion pass would recognize.
pub(super) fn create_new_event_instances_impl(
    event: &models::Event,
    instances: &[EventInstance],
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Vec<EventInstance>, Status> {
    let mut resolved = Vec::with_capacity(instances.len());
    for request_instance in instances {
        if find_existing_instance(&request_instance.id, event.id, conn).is_some() {
            resolved.push(request_instance.clone());
            continue;
        }
        let (created_instance, _) = create_instance(event, request_instance, current_user, conn)?;
        resolved.push(EventInstance {
            id: created_instance.id.to_proto_id(),
            ..request_instance.clone()
        });
    }

    // New instances are always owned by `current_user`; refresh their `event_instance_count`.
    crate::logic::update_event_counts(current_user.id, conn)
        .map_err(|_| Status::new(Code::Internal, "error_updating_event_counts"))?;

    Ok(resolved)
}

pub fn create_new_event_instances(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event_id = request.id.to_db_id_or_err("id")?;
    let event = models::get_event(event_id, &Some(current_user), conn)?;
    validate_event_edit_permission(&event, current_user, conn)?;

    create_new_event_instances_impl(&event, &request.instances, current_user, conn)?;

    Ok(super::get_events(
        GetEventsRequest {
            event_id: Some(event_id.to_proto_id()),
            ..Default::default()
        },
        &Some(current_user),
        conn,
    )?
    .events[0]
        .clone())
}

/// New instances are always authored by `user` (the caller) -- syncing to any other owner isn't
/// supported.
pub fn create_instance(
    event: &models::Event,
    instance: &EventInstance,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(models::EventInstance, models::Post), Status> {
    let media_ids = instance
        .post
        .as_ref()
        .map(|p| {
            p.media
                .iter()
                .map(|m| m.id.to_db_id_or_err("instance.post.media"))
                .collect::<Result<Vec<i64>, Status>>()
        })
        .transpose()?
        .unwrap_or_default();
    let new_post = instance.post.as_ref().map_or(
        models::NewPost {
            user_id: Some(user.id),
            parent_post_id: None,
            title: None,
            link: None,
            content: None,
            visibility: "GLOBAL_PUBLIC".to_string(),
            embed_link: false,
            context: PostContext::EventInstance.as_str_name().to_string(),
            moderation: "UNMODERATED".to_string(),
            media: vec![],
        },
        |p| models::NewPost {
            user_id: Some(user.id),
            parent_post_id: None,
            title: p.title.to_owned(),
            link: p.link.to_link(),
            content: p.content.to_owned(),
            visibility: p.visibility.to_string_visibility(),
            embed_link: p.embed_link.to_owned(),
            context: PostContext::EventInstance.as_str_name().to_string(),
            moderation: "UNMODERATED".to_string(),
            media: media_ids,
        },
    );
    let instance_post: models::Post = insert_into(posts::table)
        .values(&new_post)
        .returning(models::POST_COLUMNS)
        .get_result::<models::Post>(conn)
        .map_err(|e| {
            log::error!("Failed to create event instance post: {:?}", e);
            Status::new(Code::Internal, "failed_to_create_event_instance_post")
        })?;
    let instance = insert_into(event_instances::table)
        .values(&models::NewEventInstance {
            event_id: event.id,
            post_id: instance_post.id,
            starts_at: instance.starts_at.as_ref().unwrap().to_db(),
            ends_at: instance.ends_at.as_ref().unwrap().to_db(),
            location: instance
                .location
                .as_ref()
                .map(|c| serde_json::to_value(c).unwrap()),
            info: json!({}),
            event_sync_source_instance_id: None,
        })
        .returning(models::EVENT_INSTANCE_COLUMNS)
        .get_result::<models::EventInstance>(conn)
        .map_err(|e| {
            log::error!("Failed to create event instance: {:?}", e);
            Status::new(Code::Internal, "failed_to_create_event_instance")
        })?;
    Ok((instance, instance_post))
}
