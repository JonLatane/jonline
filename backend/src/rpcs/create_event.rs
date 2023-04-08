use diesel::*;
use serde_json::json;
use tonic::{Code, Request, Response, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::{event_instances, events, posts};

use super::validations::*;

pub fn create_event(
    request: Request<Event>,
    user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Response<Event>, Status> {
    log::info!(
        "CreateEvent called for user {}, user_id={}",
        &user.username,
        user.id
    );
    validate_permission(&user, Permission::CreateEvents)?;
    let req = request.into_inner();
    let post = match req.post {
        None => return Err(Status::new(Code::InvalidArgument, "post_required")),
        Some(p) => p,
    };
    let instances = req.instances;
    if instances.len() == 0 {
        return Err(Status::new(
            Code::InvalidArgument,
            "at_least_one_instance_required",
        ));
    }
    for instance in &instances {
        match &instance.post {
            Some(p) => {
                validate_max_length(p.link.to_owned(), "instance.post.link", 10000)?;
                validate_max_length(p.content.to_owned(), "instance.post.content", 10000)?;

                let visibility = match p.visibility() {
                    Visibility::Unknown => Visibility::GlobalPublic,
                    v => v,
                };
                match visibility {
                    Visibility::GlobalPublic => {
                        validate_permission(&user, Permission::PublishEventsGlobally)?
                    }
                    Visibility::ServerPublic => {
                        validate_permission(&user, Permission::PublishEventsLocally)?
                    }
                    _ => {}
                };
            }
            None => {}
        }
        if instance.starts_at.is_none() || instance.ends_at.is_none() {
            return Err(Status::new(
                Code::InvalidArgument,
                "start_and_end_times_required",
            ));
        }
    }

    validate_max_length(post.link.to_owned(), "post.link", 10000)?;
    validate_max_length(post.content.to_owned(), "post.content", 10000)?;

    let visibility = match post.visibility() {
        Visibility::Unknown => Visibility::GlobalPublic,
        v => v,
    };
    match visibility {
        Visibility::GlobalPublic => validate_permission(&user, Permission::PublishEventsGlobally)?,
        Visibility::ServerPublic => validate_permission(&user, Permission::PublishEventsLocally)?,
        _ => {}
    };

    let result = conn.transaction::<(
        models::Event,
        models::Post,
        Vec<(models::EventInstance, Option<models::Post>)>,
    ), diesel::result::Error, _>(|conn| {
        let event_post = insert_into(posts::table)
            .values(&models::NewPost {
                user_id: Some(user.id),
                parent_post_id: None,
                title: post.title.to_owned(),
                link: post.link.to_link(),
                content: post.content.to_owned(),
                visibility: visibility.to_string_visibility(),
                context: PostContext::Event.as_str_name().to_string(),
                preview: None,
            })
            .get_result::<models::Post>(conn)?;
        let inserted_event = insert_into(events::table)
            .values(&models::NewEvent {
                post_id: event_post.id,
                info: json!({}),
            })
            .get_result::<models::Event>(conn)?;
        let mut inserted_instances: Vec<(models::EventInstance, Option<models::Post>)> = vec![];
        for instance in &instances {
            let instance_post: Option<models::Post> = match &instance.post {
                Some(p) => Some(
                    insert_into(posts::table)
                        .values(&models::NewPost {
                            user_id: Some(user.id),
                            parent_post_id: None,
                            title: p.title.to_owned(),
                            link: p.link.to_link(),
                            content: p.content.to_owned(),
                            visibility: p.visibility.to_string_visibility(),
                            context: PostContext::Event.as_str_name().to_string(),
                            preview: None,
                        })
                        .get_result::<models::Post>(conn)?,
                ),
                None => None,
            };
            let inserted_instance = insert_into(event_instances::table)
                .values(&models::NewEventInstance {
                    event_id: inserted_event.id,
                    post_id: instance_post.as_ref().map(|p| p.id),
                    starts_at: instance.starts_at.as_ref().unwrap().to_db(),
                    ends_at: instance.ends_at.as_ref().unwrap().to_db(),
                    // location: i.location,
                    info: json!({}),
                })
                .get_result::<models::EventInstance>(conn)?;
            inserted_instances.push((inserted_instance, instance_post));
        }
        Ok((inserted_event, event_post, inserted_instances))
    });

    match result {
        Ok((event, post, instances)) => {
            log::info!("Event created! EventID: {:?}", event.id);
            Ok(Response::new(
                event.to_proto(
                    &post,
                    Some(&user),
                    &instances
                        .iter()
                        .map(|(i, p)| (i, p.as_ref(), Some(&user)))
                        .collect::<Vec<(
                            &models::EventInstance,
                            Option<&models::Post>,
                            Option<&models::User>,
                        )>>(),
                ),
            ))
        }
        Err(e) => {
            log::error!("Error creating event! {:?}", e);
            Err(Status::new(Code::Internal, "internal_error"))
        }
    }
}
