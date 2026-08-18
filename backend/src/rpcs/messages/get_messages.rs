use std::time::SystemTime;

use diesel::{
    dsl::sql,
    sql_types::{Bool, Text},
    *,
};
use diesel_full_text_search::{
    configuration::TsConfigurationByName, to_tsquery_with_search_config, TsVectorExtensions,
};
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::logic::prefix_tsquery_text;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::{message_recipients, messages, messaging_groups, users};

const PAGE_SIZE: i64 = 200;

fn sent_before(request: &GetMessagesRequest) -> Option<SystemTime> {
    request.sent_before.as_ref().map(|ts| ts.to_db())
}

// `request.search_text`, trimmed and required non-empty - mirrors `get_users::required_search_text`/
// `get_posts::get_search_posts`'s own inline check.
fn required_search_text(request: &GetMessagesRequest) -> Result<&str, Status> {
    let search_text = request
        .search_text
        .as_deref()
        .map(str::trim)
        .filter(|search_text| !search_text.is_empty())
        .ok_or(Status::new(Code::InvalidArgument, "search_text_required"))?;
    if prefix_tsquery_text(search_text).is_empty() {
        return Err(Status::new(Code::InvalidArgument, "search_text_required"));
    }
    Ok(search_text)
}

pub fn get_messages(
    request: GetMessagesRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<GetMessagesResponse, Status> {
    let is_system_listing = matches!(
        request.listing_type(),
        MessageListingType::AllSystemMessages | MessageListingType::AllSystemMessagesTextSearch
    );
    validate_permission(
        user,
        if is_system_listing {
            Permission::ReadAllSystemMessages
        } else {
            Permission::ReadPersonalMessages
        },
    )?;
    // `validate_permission` treats an anonymous (`None`) `user` as having no permissions at all,
    // so succeeding above guarantees `user` is `Some` here.
    let user = user.ok_or(Status::new(
        Code::Unauthenticated,
        "authentication_required",
    ))?;

    let cutoff = sent_before(&request);
    let result = match (
        request.to_owned().message_id,
        request.to_owned().message_group_id,
        request.to_owned().from_email,
    ) {
        (Some(message_id), _, _) => {
            get_by_message_id(user, &message_id, is_system_listing, conn)?
        }
        (_, Some(message_group_id), _) => {
            get_messaging_group_messages(user, &message_group_id, is_system_listing, cutoff, conn)?
        }
        (_, _, Some(from_email)) => {
            get_by_from_email(user, &from_email, is_system_listing, cutoff, conn)?
        }
        _ if is_system_listing => get_system_messages(
            match request.listing_type() {
                MessageListingType::AllSystemMessagesTextSearch => {
                    Some(required_search_text(&request)?)
                }
                _ => None,
            },
            cutoff,
            conn,
        )?,
        _ => get_personal_messages(
            user,
            match request.listing_type() {
                MessageListingType::PersonalMessagesTextSearch => {
                    Some(required_search_text(&request)?)
                }
                _ => None,
            },
            cutoff,
            conn,
        )?,
    };

    Ok(GetMessagesResponse {
        messages: convert_messages(&result, user.id, conn),
    })
}

fn get_by_message_id(
    user: &models::User,
    message_id: &str,
    is_system_listing: bool,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableMessage>, Status> {
    let message_db_id = message_id.to_string().to_db_id_or_err("message_id")?;
    let (message, sender, group) = messages::table
        .left_join(users::table.on(messages::from_user_id.eq(users::id.nullable())))
        .inner_join(
            messaging_groups::table.on(messages::messaging_group_id.eq(messaging_groups::id)),
        )
        .filter(messages::id.eq(message_db_id))
        .select((
            models::MESSAGE_COLUMNS,
            models::AUTHOR_COLUMNS.nullable(),
            messaging_groups::all_columns,
        ))
        .first::<(
            models::Message,
            Option<models::Author>,
            models::MessagingGroup,
        )>(conn)
        .map_err(|_| Status::new(Code::NotFound, "message_not_found"))?;

    // Non-admin access is limited to messages the user sent or was a To/Cc/Bcc recipient of -
    // matching `get_personal_messages`' own access filter (see its doc comment).
    if !is_system_listing {
        let is_bcc_recipient = message_recipients::table
            .filter(message_recipients::message_id.eq(message_db_id))
            .filter(message_recipients::user_id.eq(user.id))
            .count()
            .get_result::<i64>(conn)
            .unwrap_or(0)
            > 0;
        let is_participant = message.from_user_id == Some(user.id)
            || group.sorted_user_ids.contains(&Some(user.id))
            || is_bcc_recipient;
        if !is_participant {
            return Err(Status::new(Code::NotFound, "message_not_found"));
        }
    }

    let viewing_user_id = if is_system_listing {
        None
    } else {
        Some(user.id)
    };
    Ok(vec![MarshalableMessage(
        message,
        sender,
        Some(group),
        viewing_user_id,
    )])
}

fn get_messaging_group_messages(
    user: &models::User,
    message_group_id: &str,
    is_system_listing: bool,
    cutoff: Option<SystemTime>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableMessage>, Status> {
    let group_db_id = message_group_id
        .to_string()
        .to_db_id_or_err("message_group_id")?;
    let group = messaging_groups::table
        .find(group_db_id)
        .first::<models::MessagingGroup>(conn)
        .map_err(|_| Status::new(Code::NotFound, "messaging_group_not_found"))?;

    // Unlike `get_by_message_id`, Bcc'd recipients don't get a pass here - browsing an entire
    // group's history is exactly the access `MessagingGroup.sorted_user_ids` (deliberately
    // excluding Bcc) is meant to gate. See `models::MessagingGroup`'s doc comment.
    if !is_system_listing && !group.sorted_user_ids.contains(&Some(user.id)) {
        return Err(Status::new(Code::NotFound, "messaging_group_not_found"));
    }

    let mut query = messages::table
        .left_join(users::table.on(messages::from_user_id.eq(users::id.nullable())))
        .filter(messages::messaging_group_id.eq(group_db_id))
        .select((models::MESSAGE_COLUMNS, models::AUTHOR_COLUMNS.nullable()))
        .order(messages::created_at.desc())
        .limit(PAGE_SIZE)
        .into_boxed();

    if let Some(cutoff) = cutoff {
        query = query.filter(messages::created_at.lt(cutoff));
    }

    let viewing_user_id = if is_system_listing {
        None
    } else {
        Some(user.id)
    };
    let result = query
        .load::<(models::Message, Option<models::Author>)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_messages"))?
        .into_iter()
        .map(|(message, sender)| {
            MarshalableMessage(message, sender, Some(group.clone()), viewing_user_id)
        })
        .collect();

    Ok(result)
}

// Expands the client-side "grouped by sender" fallback a message with no visible
// `messaging_group` falls into (see `Message.messaging_group`'s own doc comment) - unlike
// `get_messaging_group_messages`, there's no server-side entity this is backed by, just a plain
// filter on `messages.email_headers->>'from'` matching some prior response's own `Message.from`
// verbatim. Since `from` is unauthenticated/spoofable (see `protos/messages.proto`'s top-level
// doc comment), so is this filter - two messages "from" the same address only actually share a
// sender if you already trust that address wasn't spoofed. Access is the same rule
// `get_personal_messages` uses (sender, a group member, or a Bcc recipient) for a non-admin
// caller; an admin (`is_system_listing`) sees every match server-wide, as with
// `get_system_messages`.
fn get_by_from_email(
    user: &models::User,
    from_email: &str,
    is_system_listing: bool,
    cutoff: Option<SystemTime>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableMessage>, Status> {
    let mut query = messages::table
        .inner_join(
            messaging_groups::table.on(messages::messaging_group_id.eq(messaging_groups::id)),
        )
        .left_join(users::table.on(messages::from_user_id.eq(users::id.nullable())))
        .left_join(
            message_recipients::table.on(message_recipients::message_id
                .eq(messages::id)
                .and(message_recipients::user_id.eq(user.id))),
        )
        .filter(messages::email_headers.is_not_null().and(
            sql::<Bool>("messages.email_headers->>'from' = ").bind::<Text, _>(from_email),
        ))
        .select((
            models::MESSAGE_COLUMNS,
            models::AUTHOR_COLUMNS.nullable(),
            messaging_groups::all_columns,
        ))
        .order(messages::created_at.desc())
        .limit(PAGE_SIZE)
        .into_boxed();

    if !is_system_listing {
        query = query.filter(
            messages::from_user_id
                .eq(user.id)
                .or(messaging_groups::sorted_user_ids.contains(vec![user.id]))
                .or(message_recipients::user_id.eq(user.id)),
        );
    }

    if let Some(cutoff) = cutoff {
        query = query.filter(messages::created_at.lt(cutoff));
    }

    let viewing_user_id = if is_system_listing {
        None
    } else {
        Some(user.id)
    };
    let result = query
        .load::<(
            models::Message,
            Option<models::Author>,
            models::MessagingGroup,
        )>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_messages"))?
        .into_iter()
        .map(|(message, sender, group)| {
            MarshalableMessage(message, sender, Some(group), viewing_user_id)
        })
        .collect();

    Ok(result)
}

// Messages the user sent, received (To/Cc, via their MessagingGroup membership), or was Bcc'd on
// (via `message_recipients` - see `models::MessagingGroup`'s doc comment on why Bcc isn't part of
// `sorted_user_ids`). `search_text` (when present) matches `messages.search_text` (subject/body) or
// the sender's `users.search_text` (username/real name), per `GetMessagesRequest.search_text`'s doc
// comment.
fn get_personal_messages(
    user: &models::User,
    search_text: Option<&str>,
    cutoff: Option<SystemTime>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableMessage>, Status> {
    let mut query = messages::table
        .inner_join(
            messaging_groups::table.on(messages::messaging_group_id.eq(messaging_groups::id)),
        )
        .left_join(users::table.on(messages::from_user_id.eq(users::id.nullable())))
        .left_join(
            message_recipients::table.on(message_recipients::message_id
                .eq(messages::id)
                .and(message_recipients::user_id.eq(user.id))),
        )
        .filter(
            messages::from_user_id
                .eq(user.id)
                .or(messaging_groups::sorted_user_ids.contains(vec![user.id]))
                .or(message_recipients::user_id.eq(user.id)),
        )
        .select((
            models::MESSAGE_COLUMNS,
            models::AUTHOR_COLUMNS.nullable(),
            messaging_groups::all_columns,
        ))
        .order(messages::created_at.desc())
        .limit(PAGE_SIZE)
        .into_boxed();

    if let Some(cutoff) = cutoff {
        query = query.filter(messages::created_at.lt(cutoff));
    }

    if let Some(search_text) = search_text {
        // "simple" (not "english") to match messages_build_search_text/users_build_search_text's
        // indexing config - see 2026-07-23-012047_add_search_text_no_stopwords.
        let message_query = to_tsquery_with_search_config(
            TsConfigurationByName("simple"),
            prefix_tsquery_text(search_text),
        );
        let sender_query = to_tsquery_with_search_config(
            TsConfigurationByName("simple"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(
            messages::search_text
                .matches(message_query)
                .or(users::search_text.matches(sender_query)),
        );
    }

    let result = query
        .load::<(
            models::Message,
            Option<models::Author>,
            models::MessagingGroup,
        )>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_messages"))?
        .into_iter()
        .map(|(message, sender, group)| {
            MarshalableMessage(message, sender, Some(group), Some(user.id))
        })
        .collect();

    Ok(result)
}

// `ALL_SYSTEM_MESSAGES(_TEXT_SEARCH)` - every Message on the server, `messaging_group` always
// shown (see `MarshalableMessage`'s doc comment). Requires `READ_ALL_SYSTEM_MESSAGES` (checked by
// `get_messages` before dispatching here).
fn get_system_messages(
    search_text: Option<&str>,
    cutoff: Option<SystemTime>,
    conn: &mut PgPooledConnection,
) -> Result<Vec<MarshalableMessage>, Status> {
    let mut query = messages::table
        .inner_join(
            messaging_groups::table.on(messages::messaging_group_id.eq(messaging_groups::id)),
        )
        .left_join(users::table.on(messages::from_user_id.eq(users::id.nullable())))
        .select((
            models::MESSAGE_COLUMNS,
            models::AUTHOR_COLUMNS.nullable(),
            messaging_groups::all_columns,
        ))
        .order(messages::created_at.desc())
        .limit(PAGE_SIZE)
        .into_boxed();

    if let Some(cutoff) = cutoff {
        query = query.filter(messages::created_at.lt(cutoff));
    }

    if let Some(search_text) = search_text {
        let message_query = to_tsquery_with_search_config(
            TsConfigurationByName("simple"),
            prefix_tsquery_text(search_text),
        );
        let sender_query = to_tsquery_with_search_config(
            TsConfigurationByName("simple"),
            prefix_tsquery_text(search_text),
        );
        query = query.filter(
            messages::search_text
                .matches(message_query)
                .or(users::search_text.matches(sender_query)),
        );
    }

    let result = query
        .load::<(
            models::Message,
            Option<models::Author>,
            models::MessagingGroup,
        )>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_messages"))?
        .into_iter()
        .map(|(message, sender, group)| MarshalableMessage(message, sender, Some(group), None))
        .collect();

    Ok(result)
}
