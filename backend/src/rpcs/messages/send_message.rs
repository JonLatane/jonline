use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::models::find_or_create_messaging_group;
use crate::protos::*;
use crate::rpcs::validations::*;
use crate::schema::{messages, users};

// Anonymous sending is supported by simply omitting the `access_token` - unlike
// `UpsertEventAttendance`'s `anonymous_attendee_auth_token` mechanism, there's no separate
// anonymous-edit path here, matching `CreatePost`/`CreateEvent`'s plain `access_token`-or-nothing
// authentication.
pub fn send_message(
    request: SendMessageRequest,
    user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<Message, Status> {
    if request.to_user_ids.is_empty() {
        return Err(Status::new(Code::InvalidArgument, "to_user_ids_required"));
    }
    let mut to_user_ids: Vec<i64> = request
        .to_user_ids
        .iter()
        .map(|id| id.to_db_id_or_err("to_user_ids"))
        .collect::<Result<_, _>>()?;
    to_user_ids.sort_unstable();
    to_user_ids.dedup();

    let existing_user_count = users::table
        .filter(users::id.eq_any(&to_user_ids))
        .count()
        .get_result::<i64>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_sending_message"))?;
    if existing_user_count as usize != to_user_ids.len() {
        return Err(Status::new(Code::InvalidArgument, "to_user_ids_invalid"));
    }

    let body_text = request
        .body_text
        .as_deref()
        .map(str::trim)
        .filter(|body_text| !body_text.is_empty())
        .ok_or(Status::new(Code::InvalidArgument, "body_text_required"))?
        .to_string();
    validate_length(&body_text, "body_text", 1, 10000)?;
    validate_max_length(request.subject.to_owned(), "subject", 255)?;

    // The messaging group covers the sender too, if any - so they see their own sent message
    // alongside the recipients' in a `PERSONAL_MESSAGES` listing (mirroring how `web/email.rs`
    // folds To/Cc recipients into the same group).
    if let Some(user) = user {
        to_user_ids.push(user.id);
    }
    let messaging_group_id = find_or_create_messaging_group(to_user_ids, conn)?;

    let message = insert_into(messages::table)
        .values(&models::NewMessage {
            from_user_id: user.map(|u| u.id),
            subject: request.subject.to_owned(),
            body_text: Some(body_text),
            email_headers: None,
            email_message_id: None,
            email_minio_path: None,
            messaging_group_id,
        })
        .returning(models::MESSAGE_COLUMNS)
        .get_result::<models::Message>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_sending_message"))?;

    let group = crate::schema::messaging_groups::table
        .find(messaging_group_id)
        .first::<models::MessagingGroup>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_sending_message"))?;
    let sender = user
        .map(|user| models::get_author(user.id, conn))
        .transpose()?;
    let viewing_user_id = user.map(|user| user.id);

    Ok(convert_messages(
        &vec![MarshalableMessage(
            message,
            sender,
            Some(group),
            viewing_user_id,
        )],
        // A freshly-sent message can't have a `message_reads` row yet, from anyone -- the exact
        // id here doesn't affect `current_user_read` (always `None`), just needs *some* `i64` to
        // satisfy `convert_messages`' signature. `0` for an anonymous sender, who has no real id
        // to use anyway.
        viewing_user_id.unwrap_or(0),
        conn,
    )
    .remove(0))
}
