use std::collections::HashMap;

use diesel::*;

use super::{load_media_lookup, MediaLookup, ToProtoAuthor, ToProtoId, ToProtoTime};
use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{message_reads, users};

/// A [`models::Message`] plus everything needed to marshal it for one particular viewer.
///
/// `2` is the message's [`models::MessagingGroup`] (every message has exactly one), and `3` is the
/// id of the user the response is being built for -- `None` for the `ALL_SYSTEM_MESSAGES(_TEXT_SEARCH)`
/// listings, which (per `Message.messaging_group`'s doc comment) always show the full group, since
/// admins have open access to all Messages. For every other listing, the group is only included if
/// the viewer is the sender or a group member -- otherwise they only have access to this Message via
/// a Bcc [`models::MessageRecipient`] row, and per that same doc comment shouldn't see who else was on it.
#[derive(Debug, Clone)]
pub struct MarshalableMessage(
    pub models::Message,
    pub Option<models::Author>,
    pub Option<models::MessagingGroup>,
    pub Option<i64>,
);

/// Batch-converts messages, loading each referenced [`models::MessagingGroup`]'s member `Author`s
/// and everyone's avatar `Media` at most once for the whole list -- mirroring
/// `post_marshaling::convert_posts`. `current_user_id` is the *actual* authenticated caller
/// (`get_messages`' own `user.id`, not `MarshalableMessage`'s own `.3` viewer id -- that field is
/// deliberately `None` for `ALL_SYSTEM_MESSAGES(_TEXT_SEARCH)` listings, see its own doc comment,
/// but `current_user_read` should still reflect the admin's own personal read status even then)
/// used to batch-load this caller's own [`models::MessageRead`] rows for every message in `data`,
/// at most once for the whole list, same "load it once, look it up per message" shape as
/// `members`/`lookup` below.
pub fn convert_messages(
    data: &Vec<MarshalableMessage>,
    current_user_id: i64,
    conn: &mut PgPooledConnection,
) -> Vec<Message> {
    let member_user_ids: Vec<i64> = data
        .iter()
        .filter_map(|m| m.2.as_ref())
        .flat_map(|group| group.sorted_user_ids.iter().filter_map(|id| *id))
        .collect();
    let members = load_author_lookup(member_user_ids, conn);

    let media_ids: Vec<i64> = data
        .iter()
        .flat_map(|m| {
            let mut ids: Vec<i64> =
                m.1.as_ref()
                    .and_then(|a| a.avatar_media_id)
                    .into_iter()
                    .collect();
            if let Some(group) = &m.2 {
                ids.extend(
                    group
                        .sorted_user_ids
                        .iter()
                        .filter_map(|id| id.as_ref())
                        .filter_map(|id| members.get(id))
                        .filter_map(|author| author.avatar_media_id),
                );
            }
            ids
        })
        .collect();
    let lookup = load_media_lookup(media_ids, conn);

    let message_ids: Vec<i64> = data.iter().map(|m| m.0.id).collect();
    let reads = load_message_read_lookup(message_ids, current_user_id, conn);

    data.iter()
        .map(|message| message.to_proto(&members, lookup.as_ref(), &reads))
        .collect()
}

/// This caller's own [`models::MessageRead`] rows for `message_ids`, keyed by `message_id` --
/// unambiguous without also keying by `user_id` since every row here is already filtered down to
/// `current_user_id`'s own reads.
fn load_message_read_lookup(
    message_ids: Vec<i64>,
    current_user_id: i64,
    conn: &mut PgPooledConnection,
) -> HashMap<i64, models::MessageRead> {
    if message_ids.is_empty() {
        return HashMap::new();
    }
    message_reads::table
        .filter(message_reads::message_id.eq_any(message_ids))
        .filter(message_reads::user_id.eq(current_user_id))
        .load::<models::MessageRead>(conn)
        .unwrap_or_default()
        .into_iter()
        .map(|read| (read.message_id, read))
        .collect()
}

fn load_author_lookup(
    user_ids: Vec<i64>,
    conn: &mut PgPooledConnection,
) -> HashMap<i64, models::Author> {
    if user_ids.is_empty() {
        return HashMap::new();
    }
    users::table
        .select(models::AUTHOR_COLUMNS)
        .filter(users::id.eq_any(user_ids))
        .load::<models::Author>(conn)
        .unwrap_or_default()
        .into_iter()
        .map(|author| (author.id, author))
        .collect()
}

pub trait ToProtoMarshalableMessage {
    fn to_proto(
        &self,
        members: &HashMap<i64, models::Author>,
        media_lookup: Option<&MediaLookup>,
        reads: &HashMap<i64, models::MessageRead>,
    ) -> Message;
}

impl ToProtoMarshalableMessage for MarshalableMessage {
    fn to_proto(
        &self,
        members: &HashMap<i64, models::Author>,
        media_lookup: Option<&MediaLookup>,
        reads: &HashMap<i64, models::MessageRead>,
    ) -> Message {
        let message = &self.0;
        let sender = &self.1;
        let viewer_id = self.3;
        let show_group = self.2.as_ref().is_some_and(|group| {
            viewer_id.is_none_or(|id| {
                message.from_user_id == Some(id) || group.sorted_user_ids.contains(&Some(id))
            })
        });
        let headers = message.email_headers();

        Message {
            id: message.id.to_proto_id(),
            sender: sender.as_ref().map(|author| author.to_proto(media_lookup)),
            messaging_group: if show_group {
                self.2
                    .as_ref()
                    .map(|group| group.to_proto(members, media_lookup))
            } else {
                None
            },
            body_text: message.body_text.to_owned().unwrap_or_default(),
            subject: message.subject.to_owned(),
            email_message_id: message.email_message_id.to_owned(),
            from: headers.from,
            to: (!headers.to.is_empty()).then(|| headers.to.join(", ")),
            cc: (!headers.cc.is_empty()).then(|| headers.cc.join(", ")),
            bcc: (!headers.bcc.is_empty()).then(|| headers.bcc.join(", ")),
            current_user_read: reads.get(&message.id).map(|read| read.to_proto()),
            created_at: Some(message.created_at.to_proto()),
        }
    }
}

pub trait ToProtoMessageRead {
    fn to_proto(&self) -> MessageRead;
}

impl ToProtoMessageRead for models::MessageRead {
    fn to_proto(&self) -> MessageRead {
        MessageRead {
            message_id: self.message_id.to_proto_id(),
            user_id: self.user_id.to_proto_id(),
            read_at: Some(self.read_at.to_proto()),
        }
    }
}

pub trait ToProtoMessagingGroup {
    fn to_proto(
        &self,
        members: &HashMap<i64, models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> MessagingGroup;
}

impl ToProtoMessagingGroup for models::MessagingGroup {
    fn to_proto(
        &self,
        members: &HashMap<i64, models::Author>,
        media_lookup: Option<&MediaLookup>,
    ) -> MessagingGroup {
        MessagingGroup {
            id: self.id.to_proto_id(),
            members: self
                .sorted_user_ids
                .iter()
                .filter_map(|id| id.as_ref())
                .map(|id| match members.get(id) {
                    Some(author) => author.to_proto(media_lookup),
                    None => deleted_member_placeholder(*id),
                })
                .collect(),
            created_at: Some(self.created_at.to_proto()),
        }
    }
}

/// A stand-in `Author` for a `MessagingGroup` member whose `users` row is gone -- deleting an
/// account (`rpcs::users::delete_user`) hard-deletes it with no FK from `sorted_user_ids` to scrub
/// after (see 2026-08-07-115738_create_messaging_groups's own doc comment on that gap), so
/// silently omitting missing ids here would misrepresent e.g. a 3-person conversation as one
/// between just its remaining members. `user_id` is kept (stable, and already exposed for every
/// other member) so the client can still tell distinct deleted members apart; everything else
/// about them is gone, so there's nothing real left to show.
fn deleted_member_placeholder(id: i64) -> Author {
    Author {
        user_id: id.to_proto_id(),
        username: Some("Deleted user".to_string()),
        avatar: None,
        real_name: None,
        permissions: vec![],
    }
}
