use diesel::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::event_instances;
// use crate::schema::event_instances::starts_at;

// use super::validations::*;
use std::collections::BTreeMap;
use std::time::SystemTime;

pub fn update_event(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event_id = request.id.to_db_id_or_err("id")?;
    let existing_event = models::get_event(event_id, &Some(current_user.clone()), conn)?;

    log::info!("Updating event: {:?}", existing_event);

    // The update_post will handle ownership checks.
    let event_with_updated_post = request.post.map_or_else(
        || {
            Err(Status::new(
                Code::InvalidArgument,
                "event must contain associated post",
            ))
        },
        |post| match post.id.to_db_id_or_err("post.id")? {
            post_id if post_id == existing_event.post_id => {
                super::update_post(post, current_user, conn).map(|updated_post| Event {
                    post: Some(updated_post),
                    ..request
                })
            }
            _ => Err(Status::new(
                Code::InvalidArgument,
                "post ID mismatches event post ID",
            )),
        },
    );

    // let event_with_updated_instaces =
    update_event_instances(event_with_updated_post?, current_user, conn)?;

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

fn update_event_instances(
    request: Event,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    let event = models::get_event(
        request.id.to_db_id_or_err("id")?,
        &Some(current_user.clone()),
        conn,
    )?;
    let existing_instance_data = models::get_event_instances(event.id, &Some(&current_user), conn)?;
    let mut existing_instances = BTreeMap::new();
    for (instance, post, user) in existing_instance_data.iter() {
        existing_instances.insert(instance.id, (instance, post, user));
    }
    // existing_instance_data.iter();
    let mut result_instance_data: Vec<EventInstance> = vec![];
    for request_instance in request.instances.iter() {
        println!("Processing input instance: {:?}", &request_instance);
        let existing_instance: Option<models::EventInstance> =
            match request_instance.id.to_db_id_or_err("instance.id") {
                Ok(instance_id) => {
                    // println!("Searching for existing instance: {}", instance_id);
                    let existing_instance = event_instances::table
                        .select(event_instances::all_columns)
                        .filter(event_instances::id.eq(instance_id))
                        .first::<models::EventInstance>(conn)
                        .ok();
                    // println!("existing_instance: {:?}", &existing_instance);
                    if existing_instance.is_none()
                        || existing_instance.as_ref().unwrap().event_id != event.id
                    {
                        // println!("Creating new instance for UI id: {}", instance.id);
                        Some(create_instance(&event, request_instance, conn)?)
                    } else {
                        // println!("Found existing instance for UI id: {}", instance.id);
                        existing_instance
                    }
                }
                Err(_) => {
                    // println!("Creating new instance for UI id: {}", instance.id);
                    Some(create_instance(&event, request_instance, conn)?)
                }
            };
        println!("Target instance: {:?}", &existing_instance);

        // TODO: Update the instance to match the request changes

        match existing_instance {
            None => {
                return Err(Status::new(
                    Code::Internal,
                    format!("failed_to_create_instance[{}]", request_instance.id),
                ))
            }
            Some(existing_instance) => {
                let mut updated_instance = existing_instance.clone();
                let starts_at = request_instance.starts_at.to_db()?;
                let ends_at = request_instance.ends_at.to_db()?;
                if starts_at > ends_at {
                    return Err(Status::new(
                        Code::InvalidArgument,
                        format!(
                            "instance[{}] starts_at must be before ends_at",
                            existing_instance.id
                        ),
                    ));
                }
                println!(
                    "Comparing instance times: {:?} - {:?} / {:?} - {:?}",
                    starts_at, ends_at, updated_instance.starts_at, updated_instance.ends_at
                );

                if starts_at != updated_instance.starts_at || ends_at != updated_instance.ends_at {
                    updated_instance.starts_at = starts_at;
                    updated_instance.ends_at = ends_at;
                    updated_instance.updated_at = SystemTime::now().into();
                }
                // updated_instance.location = instance
                //     .location
                //     .as_ref()
                //     .map(|c| serde_json::to_value(c).unwrap());
                // updated_instance.info = json!({});
                // updated_instance.post_id = None; //instance_post.as_ref().map(|p| p.id);
                println!("Updating instance: {:?}", updated_instance);
                updated_instance = diesel::update(&updated_instance)
                    .set(&updated_instance)
                    .get_result::<models::EventInstance>(conn)
                    .map_err(|e| {
                        log::error!("Failed to update event instance: {:?}", e);
                        Status::new(Code::Internal, "failed_to_update_event_instance")
                    })?;
                println!("Returning instance: {}", existing_instance.id);
                result_instance_data
                    .push(MarshalableEventInstance(updated_instance, None).to_proto(None));
            }
        }
    }

    // Delete non-present instances
    let mut result_instances = BTreeMap::new();
    for instance in result_instance_data.iter() {
        result_instances.insert(instance.id.clone(), instance);
    }
    let removed_instance_ids: Vec<i64> = existing_instance_data
        .iter()
        .filter(|(instance, _, _)| !result_instances.contains_key(&instance.id.to_proto_id()))
        .map(|(instance, _, _)| instance.id)
        .collect();
    diesel::delete(event_instances::table.filter(event_instances::id.eq_any(removed_instance_ids)))
        .execute(conn)
        .map_err(|e| {
            log::error!("Failed to delete event instances: {:?}", e);
            Status::new(Code::Internal, "failed_to_delete_event_instances")
        })?;

    Ok(Event {
        instances: result_instance_data,
        ..request
    })
}

pub fn create_instance(
    event: &models::Event,
    instance: &EventInstance,
    conn: &mut PgPooledConnection,
) -> Result<models::EventInstance, Status> {
    insert_into(event_instances::table)
        .values(&models::NewEventInstance {
            event_id: event.id,
            post_id: None, //instance_post.as_ref().map(|p| p.id),
            starts_at: instance.starts_at.as_ref().unwrap().to_db(),
            ends_at: instance.ends_at.as_ref().unwrap().to_db(),
            location: instance
                .location
                .as_ref()
                .map(|c| serde_json::to_value(c).unwrap()),
            info: json!({}),
        })
        .get_result::<models::EventInstance>(conn)
        .map_err(|e| {
            log::error!("Failed to create event instance: {:?}", e);
            Status::new(Code::Internal, "failed_to_create_event_instance")
        })
}
