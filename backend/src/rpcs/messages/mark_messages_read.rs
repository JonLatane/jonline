use std::collections::HashMap;
use std::time::SystemTime;

use diesel::upsert::excluded;
use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validations::validate_permission;
use crate::schema::{message_reads, message_recipients, messages, messaging_groups};

/// Marks (or unmarks) `request.message_ids` as read by `user`, all at once -- see
/// `MarkMessagesReadRequest`/`MessageRead`'s own doc comments. Deliberately doesn't call
/// `validate_permission` for `ReadPersonalMessages`/`ReadAllSystemMessages` the way `get_messages`
/// does -- managing your own read status on Messages you already have legitimate access to
/// (sender, group member, Bcc recipient, or an admin browsing `ALL_SYSTEM_MESSAGES`) shouldn't
/// additionally require the *listing* permission, same "just needs the recipient/sender access
/// GetMessages already requires for that Message" reasoning as `SendMessage`'s own lack of a
/// dedicated permission.
///
/// Atomic, per the RPC's own doc comment: every id in `message_ids` is access-checked *before*
/// any write happens, so a caller who (say) typos one id, or has since lost access to one message
/// in an otherwise-legitimate batch, gets a clean `message_not_found` rather than a partially
/// applied mark.
pub fn mark_messages_read(
    request: MarkMessagesReadRequest,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<MarkMessagesReadResponse, Status> {
    if request.message_ids.is_empty() {
        return Err(Status::new(Code::InvalidArgument, "message_ids_required"));
    }
    let message_db_ids: Vec<i64> = request
        .message_ids
        .iter()
        .map(|id| id.to_db_id_or_err("message_ids"))
        .collect::<Result<_, _>>()?;

    let rows = messages::table
        .inner_join(
            messaging_groups::table.on(messages::messaging_group_id.eq(messaging_groups::id)),
        )
        .filter(messages::id.eq_any(&message_db_ids))
        .select((models::MESSAGE_COLUMNS, messaging_groups::all_columns))
        .load::<(models::Message, models::MessagingGroup)>(conn)
        .map_err(|_| Status::new(Code::Internal, "error_loading_messages"))?;
    if rows.len() != message_db_ids.len() {
        // At least one requested id doesn't exist at all -- same "not found", not a separate
        // error, as an id that exists but the caller can't access (below), so this never leaks
        // which case it actually was.
        return Err(Status::new(Code::NotFound, "message_not_found"));
    }

    let bcc_message_ids: Vec<i64> = message_recipients::table
        .filter(message_recipients::message_id.eq_any(&message_db_ids))
        .filter(message_recipients::user_id.eq(user.id))
        .select(message_recipients::message_id)
        .load::<i64>(conn)
        .unwrap_or_default();

    let is_admin = validate_permission(&Some(user), Permission::ReadAllSystemMessages).is_ok();
    // Same access check as `get_by_message_id` (see its own doc comment) -- sender, group member,
    // or Bcc recipient of *this* Message -- with an `ADMIN`/`ReadAllSystemMessages` bypass for the
    // same reason `get_messages` gives system-listing admins open access to every Message.
    let all_accessible = rows.iter().all(|(message, group)| {
        is_admin
            || message.from_user_id == Some(user.id)
            || group.sorted_user_ids.contains(&Some(user.id))
            || bcc_message_ids.contains(&message.id)
    });
    if !all_accessible {
        return Err(Status::new(Code::NotFound, "message_not_found"));
    }

    let message_reads: Vec<models::MessageRead> = if request.unread {
        delete(
            message_reads::table
                .filter(message_reads::message_id.eq_any(&message_db_ids))
                .filter(message_reads::user_id.eq(user.id)),
        )
        .execute(conn)
        .map_err(|_| Status::new(Code::Internal, "error_marking_messages_unread"))?;

        // No row to `RETURNING` once deleted -- `read_at` here is just the time of this unmark
        // request, not a meaningful "last read" timestamp (see `MessageRead.read_at`'s own doc).
        let unmarked_at = SystemTime::now();
        message_db_ids
            .iter()
            .map(|&message_id| models::MessageRead {
                message_id,
                user_id: user.id,
                read_at: unmarked_at,
            })
            .collect()
    } else {
        let read_at = SystemTime::now();
        let new_reads: Vec<models::NewMessageRead> = message_db_ids
            .iter()
            .map(|&message_id| models::NewMessageRead {
                message_id,
                user_id: user.id,
                read_at,
            })
            .collect();

        insert_into(message_reads::table)
            .values(&new_reads)
            .on_conflict((message_reads::message_id, message_reads::user_id))
            .do_update()
            .set(message_reads::read_at.eq(excluded(message_reads::read_at)))
            .get_results::<models::MessageRead>(conn)
            .map_err(|_| Status::new(Code::Internal, "error_marking_messages_read"))?
    };

    // `RETURNING`/the synthetic "unread" rows above aren't guaranteed to come back in
    // `message_db_ids`' own order -- re-sort so the response lines up with
    // `MarkMessagesReadResponse`'s own doc ("one `MessageRead` per `message_ids` entry, in the
    // same order").
    let by_message_id: HashMap<i64, models::MessageRead> = message_reads
        .into_iter()
        .map(|read| (read.message_id, read))
        .collect();

    Ok(MarkMessagesReadResponse {
        message_reads: message_db_ids
            .iter()
            .filter_map(|id| by_message_id.get(id))
            .map(|read| read.to_proto())
            .collect(),
    })
}
