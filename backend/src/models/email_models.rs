use std::time::SystemTime;

use diesel::*;
use serde::{Deserialize, Serialize};

use super::User;
use crate::schema::{email_message_recipients, email_messages};

#[derive(Debug, Queryable, Identifiable, Clone)]
#[diesel(table_name = email_messages)]
pub struct EmailMessage {
    pub id: i64,
    pub message_id: String,
    pub minio_path: String,
    pub headers: serde_json::Value,
    pub created_at: SystemTime,
}

impl EmailMessage {
    /// Typed view of `headers`. Falls back to an empty (all-default) [`EmailHeaders`] if the
    /// column somehow holds something that doesn't parse.
    pub fn headers(&self) -> EmailHeaders {
        serde_json::from_value(self.headers.clone()).unwrap_or_default()
    }
}

#[derive(Debug, Insertable)]
#[diesel(table_name = email_messages)]
pub struct NewEmailMessage {
    pub message_id: String,
    pub minio_path: String,
    pub headers: serde_json::Value,
}

/// `EmailMessage.headers`' typed shape. Address fields hold raw `To`/`Cc`/`Bcc`/`From` header
/// values (e.g. `"Jon Latané <jon@jonline.io>"`), not just bare addresses, since that's what's
/// useful to render without re-parsing the MIME blob in MinIO. `body_preview` is truncated to
/// (at most) 500 chars of the message's plaintext body.
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
    #[serde(skip_serializing_if = "Option::is_none")]
    pub subject: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub body_preview: Option<String>,
}

/// Which envelope field a [`EmailMessageRecipient`] was addressed through. Stored as a plain
/// `VARCHAR` (see `recipient_type`, matching this crate's convention for other Postgres-enum-ish
/// columns, e.g. `Visibility`/`Moderation`), rather than a Postgres enum, so new types don't need
/// a migration.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RecipientType {
    To,
    Cc,
    Bcc,
}

impl RecipientType {
    pub fn as_str(&self) -> &'static str {
        match self {
            RecipientType::To => "to",
            RecipientType::Cc => "cc",
            RecipientType::Bcc => "bcc",
        }
    }
}

#[derive(Debug, Queryable, Identifiable, Associations, Clone)]
#[diesel(belongs_to(EmailMessage))]
#[diesel(belongs_to(User))]
#[diesel(table_name = email_message_recipients)]
pub struct EmailMessageRecipient {
    pub id: i64,
    pub email_message_id: i64,
    pub user_id: i64,
    pub recipient_type: String,
    pub created_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = email_message_recipients)]
pub struct NewEmailMessageRecipient {
    pub email_message_id: i64,
    pub user_id: i64,
    pub recipient_type: String,
}
