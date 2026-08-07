use diesel::*;
use mail_parser::{Addr, Address};
use rocket::{data::ToByteUnit, http::Status, routes, Data, Route, State};
use uuid::Uuid;

use crate::models;
use crate::models::MESSAGE_COLUMNS;
use crate::schema::{self, message_recipients, messages, users};
use crate::web::headers::RecipientsHeader;
use crate::web::RocketState;

lazy_static! {
    pub static ref EMAIL_ENDPOINTS: Vec<Route> = routes![create_email_message];
}

/// The largest inbound email (including attachments) this endpoint will accept. Stalwart should
/// already be rejecting larger messages at SMTP time -- this is a backstop, not the primary
/// limit.
const MAX_EMAIL_SIZE_MIB: u64 = 50;

/// Delivery endpoint called by the Stalwart mail server (see `deploys/email`) once it accepts an
/// inbound message addressed to one of this namespace's domains. This is mounted *only* on the
/// internal-only Rocket instance on port 27705 (see `servers::start_rocket_internal`) -- never on
/// the public 80/443/8000 instances -- since it has no authentication of its own and trusts its
/// caller completely; that trust boundary must be enforced at the network layer (e.g. a
/// NetworkPolicy restricting port 27705 to Stalwart's pod).
///
/// `X-Jonline-Email-Recipients` carries the SMTP envelope's `RCPT TO` addresses (comma-separated)
/// -- this is the envelope, not the message's `To`/`Cc` headers, so it's the only place Bcc'd
/// recipients show up at all. The request body is the raw MIME message. Recipients whose
/// username doesn't match any user in this namespace are silently skipped (Stalwart is expected
/// to have already validated deliverability before calling this endpoint); if none match, the
/// whole message is dropped.
#[rocket::post("/email", data = "<message>")]
pub async fn create_email_message(
    message: Data<'_>,
    recipients_header: RecipientsHeader<'_>,
    state: &State<RocketState>,
) -> Result<String, Status> {
    let capped_message = message
        .open(MAX_EMAIL_SIZE_MIB.mebibytes())
        .into_bytes()
        .await
        .map_err(|_| Status::InternalServerError)?;
    if !capped_message.is_complete() {
        return Err(Status::PayloadTooLarge);
    }
    let raw_message = capped_message.into_inner();

    let parsed = mail_parser::MessageParser::default()
        .parse(&raw_message)
        .ok_or(Status::BadRequest)?;

    let email_message_id = parsed
        .message_id()
        .map(|id| id.to_string())
        .unwrap_or_else(|| format!("<generated-{}@jonline.internal>", Uuid::new_v4()));

    let mut conn = state.pool.get().map_err(|_| Status::InternalServerError)?;

    let mut recipients: Vec<(i64, models::RecipientType)> = vec![];
    for address in recipients_header
        .0
        .split(',')
        .map(|address| address.trim())
        .filter(|address| !address.is_empty())
    {
        let username = match address.split('@').next() {
            Some(username) if !username.is_empty() => username,
            _ => continue,
        };
        let user_id: Option<i64> = schema::users::table
            .select(users::id)
            .filter(users::username.eq(username))
            .first(&mut conn)
            .optional()
            .map_err(|_| Status::InternalServerError)?;
        let Some(user_id) = user_id else { continue };

        let recipient_type = if parsed.to().is_some_and(|to| to.contains(address)) {
            models::RecipientType::To
        } else if parsed.cc().is_some_and(|cc| cc.contains(address)) {
            models::RecipientType::Cc
        } else {
            models::RecipientType::Bcc
        };
        recipients.push((user_id, recipient_type));
    }

    if recipients.is_empty() {
        return Err(Status::NotFound);
    }

    let email_headers = models::EmailHeaders {
        from: parsed.from().and_then(display_address),
        to: collect_addresses(parsed.to()),
        cc: collect_addresses(parsed.cc()),
        // Bcc recipients are (by design) never present in the message's own headers -- see
        // `recipients` above, derived from the SMTP envelope instead.
        bcc: vec![],
    };

    let email_minio_path = format!("email/{}.eml", Uuid::new_v4());
    state
        .bucket
        .put_object_with_content_type(&email_minio_path, &raw_message, "message/rfc822")
        .await
        .map_err(|_| Status::InternalServerError)?;

    let new_message = models::NewMessage {
        subject: parsed.subject().map(|subject| subject.to_string()),
        body_text: parsed.body_text(0).map(|body| body.to_string()),
        email_headers: Some(serde_json::to_value(email_headers).unwrap()),
        email_message_id: Some(email_message_id.clone()),
        email_minio_path: Some(email_minio_path),
    };

    let message = match insert_into(messages::table)
        .values(&new_message)
        .returning(MESSAGE_COLUMNS)
        .get_result::<models::Message>(&mut conn)
    {
        Ok(message) => message,
        // Stalwart retries delivery on transient failure -- a unique violation here means we've
        // already stored this Message-ID, so treat it as success and reuse the existing row
        // rather than storing (and MinIO-uploading) a duplicate.
        Err(diesel::result::Error::DatabaseError(
            diesel::result::DatabaseErrorKind::UniqueViolation,
            _,
        )) => messages::table
            .select(MESSAGE_COLUMNS)
            .filter(messages::email_message_id.eq(&email_message_id))
            .first::<models::Message>(&mut conn)
            .map_err(|_| Status::InternalServerError)?,
        Err(_) => return Err(Status::InternalServerError),
    };

    for (user_id, recipient_type) in &recipients {
        insert_into(message_recipients::table)
            .values(&models::NewMessageRecipient {
                message_id: message.id,
                user_id: *user_id,
                recipient_type: *recipient_type,
            })
            .on_conflict((
                message_recipients::message_id,
                message_recipients::user_id,
            ))
            .do_nothing()
            .execute(&mut conn)
            .map_err(|_| Status::InternalServerError)?;
    }

    Ok(message.id.to_string())
}

fn format_addr(addr: &Addr) -> Option<String> {
    match (addr.name(), addr.address()) {
        (Some(name), Some(address)) => Some(format!("{} <{}>", name, address)),
        (None, Some(address)) => Some(address.to_string()),
        _ => None,
    }
}

fn collect_addresses(address: Option<&Address>) -> Vec<String> {
    address
        .map(|address| address.iter().filter_map(format_addr).collect())
        .unwrap_or_default()
}

fn display_address(address: &Address) -> Option<String> {
    address.iter().next().and_then(format_addr)
}
