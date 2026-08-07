use std::time::SystemTime;

use diesel::*;
use diesel_derive_enum::DbEnum;
use serde::{Deserialize, Serialize};

use super::User;
use crate::schema::{message_recipients, messages};

#[derive(Debug, Queryable, Identifiable, Clone)]
#[diesel(table_name = messages)]
pub struct Message {
    pub id: i64,
    pub from_user_id: Option<i64>,
    pub subject: Option<String>,
    pub body_text: Option<String>,
    pub email_headers: Option<serde_json::Value>,
    pub email_message_id: Option<String>,
    pub email_minio_path: Option<String>,
    pub created_at: SystemTime,
}

impl Message {
    /// Typed view of `email_headers`. Falls back to an empty (all-default) [`EmailHeaders`] if
    /// the column is unset or somehow holds something that doesn't parse.
    pub fn email_headers(&self) -> EmailHeaders {
        self.email_headers
            .as_ref()
            .and_then(|headers| serde_json::from_value(headers.clone()).ok())
            .unwrap_or_default()
    }
}

/// Explicit column list for `messages`, excluding `search_text` -- a denormalized tsvector used
/// only for full-text search filtering/indexing, it has no corresponding field on `Message` since
/// it's never read back into application code (mirroring `post_models::POST_COLUMNS`).
pub const MESSAGE_COLUMNS: (
    messages::id,
    messages::from_user_id,
    messages::subject,
    messages::body_text,
    messages::email_headers,
    messages::email_message_id,
    messages::email_minio_path,
    messages::created_at,
) = (
    messages::id,
    messages::from_user_id,
    messages::subject,
    messages::body_text,
    messages::email_headers,
    messages::email_message_id,
    messages::email_minio_path,
    messages::created_at,
);

#[derive(Debug, Insertable)]
#[diesel(table_name = messages)]
pub struct NewMessage {
    pub subject: Option<String>,
    pub body_text: Option<String>,
    pub email_headers: Option<serde_json::Value>,
    pub email_message_id: Option<String>,
    pub email_minio_path: Option<String>,
}

/// `Message.email_headers`' typed shape. Address fields hold raw `To`/`Cc`/`Bcc`/`From` header
/// values (e.g. `"Jon Latané <jon@jonline.io>"`), not just bare addresses, since that's what's
/// useful to render without re-parsing the MIME blob in MinIO.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EmailHeaders {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub from: Option<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub to: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub cc: Vec<String>,
    #[serde(skip_serializing_if = "Vec::is_empty", default)]
    pub bcc: Vec<String>,
}

/// Which envelope field a [`MessageRecipient`] was addressed through, backed by the Postgres
/// `recipient_type` enum (see 2026-08-02-120000_create_messages). `Direct` is for future in-app
/// messages that aren't email at all (see `messages.from_user_id`); the `/email` endpoint only
/// ever produces `To`/`Cc`/`Bcc`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, DbEnum)]
#[ExistingTypePath = "crate::schema::sql_types::RecipientType"]
pub enum RecipientType {
    To,
    Cc,
    Bcc,
    Direct,
}

#[derive(Debug, Queryable, Identifiable, Associations, Clone)]
#[diesel(belongs_to(Message))]
#[diesel(belongs_to(User))]
#[diesel(table_name = message_recipients)]
pub struct MessageRecipient {
    pub id: i64,
    pub message_id: i64,
    pub user_id: i64,
    pub recipient_type: RecipientType,
    pub created_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = message_recipients)]
pub struct NewMessageRecipient {
    pub message_id: i64,
    pub user_id: i64,
    pub recipient_type: RecipientType,
}
