use diesel::*;
use serde_json::json;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::{event_instances, events, posts, users};

use crate::rpcs::validations::*;

pub fn create_event(
    request: Event,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<Event, Status> {
    log::info!(
        "CreateEvent called for user {}, user_id={}",
        &user.username,
        user.id
    );
    validate_permission(&Some(&user), Permission::CreateEvents)?;
    let configuration = crate::rpcs::get_server_configuration_proto(conn)?;
    let moderation = match &configuration
        .event_settings
        .unwrap_or_default()
        .default_moderation()
    {
        Moderation::Pending => Moderation::Pending.as_str_name(),
        _ => Moderation::Unmoderated.as_str_name(),
    };
    let post = match request.post {
        None => return Err(Status::new(Code::InvalidArgument, "post_required")),
        Some(p) => p,
    };

    for media in &post.media {
        media.id.to_db_id_or_err("media")?;
        //TODO further media ID validations?
    }
    let instances = request.instances;
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
                for m in &p.media {
                    m.id.to_db_id_or_err("instance.media")?;
                }
                let visibility = match p.visibility() {
                    Visibility::Unknown => Visibility::GlobalPublic,
                    v => v,
                };
                match visibility {
                    Visibility::GlobalPublic => {
                        validate_permission(&Some(&user), Permission::PublishEventsGlobally)?
                    }
                    Visibility::ServerPublic => {
                        validate_permission(&Some(&user), Permission::PublishEventsLocally)?
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
        Visibility::GlobalPublic => {
            validate_permission(&Some(user), Permission::PublishEventsGlobally)?
        }
        Visibility::ServerPublic => {
            validate_permission(&Some(user), Permission::PublishEventsLocally)?
        }
        _ => {}
    };
    let author = user.to_author();
    // models::Author {
    //     id: user.id,
    //     username: user.username.clone(),
    //     avatar_media_id: user.avatar_media_id,
    //     real_name: user.real_name.clone(),
    //     permissions: user.permissions()
    // };
    let result = conn.transaction::<MarshalableEvent, diesel::result::Error, _>(|conn| {
        let event_post = insert_into(posts::table)
            .values(&models::NewPost {
                user_id: Some(user.id),
                parent_post_id: None,
                title: post.title.to_owned(),
                link: post.link.to_link(),
                content: post.content.to_owned(),
                visibility: visibility.to_string_visibility(),
                embed_link: post.embed_link.to_owned(),
                context: PostContext::Event.to_string_post_context(),
                moderation: moderation.to_string(),
                media: post
                    .media
                    .iter()
                    .map(|m| m.id.to_db_id().unwrap())
                    .collect(),
            })
            .get_result::<models::Post>(conn)?;
        let inserted_event = insert_into(events::table)
            .values(&models::NewEvent {
                post_id: event_post.id,
                info: serde_json::to_value(request.info).unwrap_or(json!({})),
            })
            .get_result::<models::Event>(conn)?;
        let mut inserted_instances: Vec<MarshalableEventInstance> = vec![];
        for instance in &instances {
            let new_post = instance.post.as_ref().map_or(
                models::NewPost {
                    user_id: Some(user.id),
                    parent_post_id: None,
                    title: None,
                    link: None,
                    content: None,
                    visibility: post.visibility.to_string_visibility(),
                    embed_link: false,
                    context: PostContext::EventInstance.as_str_name().to_string(),
                    moderation: moderation.to_string(),
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
                    moderation: moderation.to_string(),
                    media: p.media.iter().map(|m| m.id.to_db_id().unwrap()).collect(),
                },
            );
            let instance_post: models::Post = insert_into(posts::table)
                .values(&new_post)
                .get_result::<models::Post>(conn)?;
            // let instance_post: Option<models::Post> = match &instance.post {
            //     Some(p) => Some(
            //         insert_into(posts::table)
            //             .values(&models::NewPost {
            //                 user_id: Some(user.id),
            //                 parent_post_id: None,
            //                 title: p.title.to_owned(),
            //                 link: p.link.to_link(),
            //                 content: p.content.to_owned(),
            //                 visibility: p.visibility.to_string_visibility(),
            //                 embed_link: p.embed_link.to_owned(),
            //                 context: PostContext::EventInstance.as_str_name().to_string(),
            //                 moderation: moderation.to_string(),
            //                 media: p.media.iter().map(|m| m.id.to_db_id().unwrap()).collect(),
            //             })
            //             .get_result::<models::Post>(conn)?,
            //     ),
            //     None => None,
            // };
            let inserted_instance = insert_into(event_instances::table)
                .values(&models::NewEventInstance {
                    event_id: inserted_event.id,
                    post_id: instance_post.id,
                    starts_at: instance.starts_at.as_ref().unwrap().to_db(),
                    ends_at: instance.ends_at.as_ref().unwrap().to_db(),
                    location: instance
                        .location
                        .as_ref()
                        .map(|c| serde_json::to_value(c).unwrap()),
                    info: json!({}),
                })
                .get_result::<models::EventInstance>(conn)?;
            let marshalable_instance = MarshalableEventInstance(
                inserted_instance,
                MarshalablePost(instance_post, Some(author.clone()), None, None, vec![]),
            );
            inserted_instances.push(marshalable_instance);

            update(users::table)
                .filter(users::id.eq(user.id))
                .set(users::event_count.eq(users::event_count + 1))
                .execute(conn)?;
        }
        Ok(MarshalableEvent(
            inserted_event,
            MarshalablePost(event_post, Some(author), None, None, vec![]),
            inserted_instances,
        ))
    });

    match result {
        Ok(marshalable_event) => {
            let event = &marshalable_event.0;
            let marshalable_post = &marshalable_event.1;
            let post = &marshalable_post.0;
            let instances = &marshalable_event.2;
            log::info!("Event created! EventID: {:?}", event.id);
            let mut media_ids = post.media.clone();
            user.avatar_media_id.map(|id| media_ids.push(Some(id)));
            media_ids.append(
                &mut instances
                    .iter()
                    .map(|MarshalableEventInstance(_, p)| p.0.media.clone())
                    .flatten()
                    .filter(|v| v.is_some())
                    // .map(|v| v.unwrap())
                    .collect::<Vec<Option<i64>>>(),
            );
            let media_references: Vec<models::MediaReference> = models::get_all_media(
                media_ids
                    .iter()
                    .filter(|v| v.is_some())
                    .map(|v| v.unwrap())
                    .collect(),
                conn,
            )?;
            let media_lookup: MediaLookup = media_lookup(media_references);
            // let author = models::Author {
            //     id: user.id,
            //     username: user.username,
            //     avatar_media_id: user.avatar_media_id,
            // };
            Ok(marshalable_event.clone().to_proto(Some(&media_lookup)))
        }
        Err(e) => {
            log::error!("Error creating event! {:?}", e);
            Err(Status::new(Code::Internal, "internal_error"))
        }
    }
}
