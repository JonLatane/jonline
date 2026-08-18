use diesel::*;
use mail_parser::{Addr, Address};
use rocket::{
    data::ToByteUnit, http::Status, response::content::RawJson, routes, Data, Route, State,
};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::models;
use crate::models::{find_or_create_messaging_group, MESSAGE_COLUMNS};
use crate::schema::{self, message_recipients, messages, users};
use crate::web::RocketState;

lazy_static! {
    pub static ref EMAIL_ENDPOINTS: Vec<Route> = routes![create_email_message];
}

/// The largest inbound email (including attachments) this endpoint will accept. Stalwart should
/// already be rejecting larger messages at SMTP time -- this is a backstop, not the primary
/// limit.
const MAX_EMAIL_SIZE_MIB: u64 = 50;

/// Body shape of Stalwart's `data`-stage MTA Hook request (see
/// https://stalw.art/docs/mta/filter/mtahooks/) -- a JSON object, not a raw MIME stream. Only the
/// fields this endpoint actually needs are modeled; unknown fields (`context`, `envelope.from`,
/// `message.serverHeaders`, `message.size`, ...) are ignored by default (no
/// `deny_unknown_fields`).
#[derive(Deserialize)]
struct MtaHookRequest {
    envelope: MtaHookEnvelope,
    message: MtaHookMessage,
}

#[derive(Deserialize)]
struct MtaHookEnvelope {
    to: Vec<MtaHookAddress>,
}

#[derive(Deserialize)]
struct MtaHookAddress {
    address: String,
}

/// `headers` are `[name, value]` pairs, already unfolded to one line each; `contents` is the raw
/// body (everything after the header block) as it appeared on the wire. Concatenating the two
/// back together with a blank-line separator reconstitutes an RFC822 message `mail_parser` can
/// parse, including multipart/attachments -- Stalwart only splits at the top-level header/body
/// boundary, it doesn't touch nested MIME part headers within `contents`.
#[derive(Deserialize)]
struct MtaHookMessage {
    headers: Vec<(String, String)>,
    contents: String,
}

/// Stalwart doesn't just check the HTTP status of a hook call -- it parses the response *body* as
/// this shape (see https://stalw.art/docs/mta/filter/mtahooks/) and treats a body it can't parse
/// as a hook failure regardless of status code, which -- combined with the `MtaHook`'s
/// `tempFailOnError: true` -- surfaces to the sending client as a `451` temp-fail. `{"action":
/// "accept"}` is the minimal response that tells Stalwart to keep going with no modifications.
#[derive(Serialize)]
struct MtaHookResponse {
    action: &'static str,
}

/// Delivery endpoint called by the Stalwart mail server (see `deploys/email`) once it accepts an
/// inbound message addressed to one of this namespace's domains. This is mounted *only* on the
/// internal-only Rocket instance on port 27705 (see `servers::start_rocket_internal`) -- never on
/// the public 80/443/8000 instances -- since it has no authentication of its own and trusts its
/// caller completely; that trust boundary must be enforced at the network layer (e.g. a
/// NetworkPolicy restricting port 27705 to Stalwart's pod).
///
/// The request body is Stalwart's MTA Hook JSON payload (`MtaHookRequest` above) -- recipients
/// come from `envelope.to`, which is the SMTP envelope's `RCPT TO` addresses, not the message's
/// `To`/`Cc` headers, so it's the only place Bcc'd recipients show up at all. Recipients whose
/// username doesn't match any user in this namespace are silently skipped (Stalwart is expected
/// to have already validated deliverability before calling this endpoint); if none match, the
/// whole message is dropped.
#[rocket::post("/email", data = "<body>")]
pub async fn create_email_message(
    body: Data<'_>,
    state: &State<RocketState>,
) -> Result<RawJson<String>, Status> {
    let capped_body = body
        .open(MAX_EMAIL_SIZE_MIB.mebibytes())
        .into_bytes()
        .await
        .map_err(|_| Status::InternalServerError)?;
    if !capped_body.is_complete() {
        return Err(Status::PayloadTooLarge);
    }
    let capped_body = capped_body.into_inner();

    let payload: MtaHookRequest =
        serde_json::from_slice(&capped_body).map_err(|_| Status::BadRequest)?;

    let raw_message = build_raw_message(&payload.message.headers, &payload.message.contents);

    let parsed = mail_parser::MessageParser::default()
        .parse(&raw_message)
        .ok_or(Status::BadRequest)?;

    let message_id = parsed
        .message_id()
        .map(|id| id.to_string())
        .unwrap_or_else(|| format!("<generated-{}@jonline.internal>", Uuid::new_v4()));

    let mut conn = state.pool.get().map_err(|_| Status::InternalServerError)?;

    let mut recipients: Vec<(i64, models::RecipientType)> = vec![];
    for address in payload
        .envelope
        .to
        .iter()
        .map(|recipient| recipient.address.trim())
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

    // The messaging_group is keyed on To/Cc recipients only -- Bcc'd recipients are deliberately
    // excluded (see 2026-08-07-115738_create_messaging_groups) since they're invisible to everyone
    // else on the message. Inbound email never has a local from_user_id (see `Message` above), so
    // there's no sender to fold in here the way there will be for future in-app direct messages.
    let group_user_ids: Vec<i64> = recipients
        .iter()
        .filter(|(_, recipient_type)| *recipient_type != models::RecipientType::Bcc)
        .map(|(user_id, _)| *user_id)
        .collect();
    let messaging_group_id = find_or_create_messaging_group(group_user_ids, &mut conn)
        .map_err(|_| Status::InternalServerError)?;

    let email_minio_path = format!("email/{}.eml", Uuid::new_v4());
    state
        .bucket
        .put_object_with_content_type(&email_minio_path, &raw_message, "message/rfc822")
        .await
        .map_err(|_| Status::InternalServerError)?;

    let new_message = models::NewMessage {
        from_user_id: None,
        subject: parsed.subject().map(|subject| subject.to_string()),
        body_text: parsed.body_text(0).map(|body| body.to_string()),
        email_headers: Some(serde_json::to_value(email_headers).unwrap()),
        email_message_id: Some(message_id.clone()),
        email_minio_path: Some(email_minio_path),
        messaging_group_id,
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
            .filter(messages::email_message_id.eq(&message_id))
            .first::<models::Message>(&mut conn)
            .map_err(|_| Status::InternalServerError)?,
        Err(_) => return Err(Status::InternalServerError),
    };

    // Only Bcc rows go into message_recipients now -- To/Cc recipients are already captured by
    // the message's group (see messaging_group_id above), which is how the UI will look them up.
    for (user_id, recipient_type) in recipients
        .iter()
        .filter(|(_, recipient_type)| *recipient_type == models::RecipientType::Bcc)
    {
        insert_into(message_recipients::table)
            .values(&models::NewMessageRecipient {
                message_id: message.id,
                user_id: *user_id,
                recipient_type: *recipient_type,
            })
            .on_conflict((message_recipients::message_id, message_recipients::user_id))
            .do_nothing()
            .execute(&mut conn)
            .map_err(|_| Status::InternalServerError)?;
    }

    Ok(RawJson(
        serde_json::to_string(&MtaHookResponse { action: "accept" }).unwrap(),
    ))
}

/// Reconstitutes an RFC822 message from a Stalwart MTA Hook's `[name, value]` header pairs and
/// body `contents` (see `MtaHookMessage`'s doc comment). Also used by the `repair_email_messages`
/// bin to re-derive fields for messages stored before this function sanitized each `value` (see
/// that bin's doc comment for why that mattered).
///
/// `sanitize_header_value` is load-bearing: Stalwart's hook values come back containing their own
/// embedded line terminators (contrary to the clean, terminator-free examples in
/// https://stalw.art/docs/mta/filter/mtahooks/) -- at minimum a trailing one, and for
/// server-generated multi-line headers like `Received`, seemingly internal ones too (still
/// present despite the docs' "already unfolded to one line" claim). Appending our own `\r\n`
/// unconditionally after an already-terminated value produced a blank line -- `mail_parser` treats
/// the first blank line as the header/body boundary, so as little as one such header could
/// silently swallow the entire rest of the message, headers included, into `body_text`. Collapsing
/// every embedded terminator (plus the fold's leading whitespace, if any) down to a single space
/// guarantees each header is truly one line before this function adds its own single `\r\n`,
/// regardless of how many terminators -- or where -- Stalwart's value already carried.
pub fn build_raw_message(headers: &[(String, String)], contents: &str) -> Vec<u8> {
    let mut raw_message = Vec::new();
    for (name, value) in headers {
        raw_message.extend_from_slice(name.as_bytes());
        raw_message.extend_from_slice(b": ");
        raw_message.extend_from_slice(sanitize_header_value(value).as_bytes());
        raw_message.extend_from_slice(b"\r\n");
    }
    raw_message.extend_from_slice(b"\r\n");
    raw_message.extend_from_slice(contents.as_bytes());
    raw_message
}

/// Collapses a header value to a single line: splits on any CR/LF, trims each fragment (removing
/// a fold's leading whitespace), drops fragments left empty by a leading/trailing/doubled
/// terminator, and rejoins with a single space. A value with no embedded terminators at all
/// passes through unchanged (`trim`'s outer whitespace aside).
pub fn sanitize_header_value(value: &str) -> String {
    value
        .split(['\r', '\n'])
        .map(str::trim)
        .filter(|fragment| !fragment.is_empty())
        .collect::<Vec<_>>()
        .join(" ")
}

fn format_addr(addr: &Addr) -> Option<String> {
    match (addr.name(), addr.address()) {
        (Some(name), Some(address)) => Some(format!("{} <{}>", name, address)),
        (None, Some(address)) => Some(address.to_string()),
        _ => None,
    }
}

pub fn collect_addresses(address: Option<&Address>) -> Vec<String> {
    address
        .map(|address| address.iter().filter_map(format_addr).collect())
        .unwrap_or_default()
}

pub fn display_address(address: &Address) -> Option<String> {
    address.iter().next().and_then(format_addr)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sanitize_header_value_passes_through_a_clean_value() {
        assert_eq!(sanitize_header_value(" jon@ato.band"), "jon@ato.band");
    }

    #[test]
    fn sanitize_header_value_strips_a_trailing_terminator() {
        // The shape Stalwart actually sends: `value` already CRLF-terminated (see
        // `build_raw_message`'s doc comment for why appending our own unconditionally broke
        // parsing).
        assert_eq!(sanitize_header_value(" jon@ato.band\r\n"), "jon@ato.band");
    }

    #[test]
    fn sanitize_header_value_unfolds_an_embedded_break() {
        assert_eq!(
            sanitize_header_value("from foo\r\n\tby bar"),
            "from foo by bar"
        );
    }

    /// Regression test for the header-reconstruction bug itself: reproduces the exact
    /// production symptom (see `build_raw_message`'s doc comment) -- every header value carrying
    /// its own trailing CRLF -- and confirms `build_raw_message` now yields a message
    /// `mail_parser` parses correctly instead of silently swallowing every header past the first
    /// into `body_text`.
    #[test]
    fn build_raw_message_survives_stalwart_style_terminated_header_values() {
        let headers = vec![
            ("To".to_string(), " jon@ato.band\r\n".to_string()),
            ("From".to_string(), " someone@example.com\r\n".to_string()),
            ("Subject".to_string(), " Test\r\n".to_string()),
            (
                "Message-Id".to_string(),
                " <abc123@example.com>\r\n".to_string(),
            ),
        ];
        let raw_message = build_raw_message(&headers, "Test message.\r\n");

        let parsed = mail_parser::MessageParser::default()
            .parse(&raw_message)
            .expect("should parse as a valid message");

        assert_eq!(parsed.subject(), Some("Test"));
        assert_eq!(parsed.message_id(), Some("abc123@example.com"));
        assert_eq!(
            parsed.from().and_then(display_address),
            Some("someone@example.com".to_string())
        );
        assert_eq!(
            collect_addresses(parsed.to()),
            vec!["jon@ato.band".to_string()]
        );
        assert_eq!(parsed.body_text(0).as_deref(), Some("Test message.\r\n"));
    }

    #[test]
    fn build_raw_message_still_works_with_clean_terminator_free_values() {
        // The shape https://stalw.art/docs/mta/filter/mtahooks/'s own examples show -- covered
        // separately since it's what a naive reading of the docs would lead you to test against,
        // and wouldn't have caught the bug above on its own.
        let headers = vec![
            ("To".to_string(), " jon@ato.band".to_string()),
            ("Subject".to_string(), " Test".to_string()),
        ];
        let raw_message = build_raw_message(&headers, "Test message.\r\n");

        let parsed = mail_parser::MessageParser::default()
            .parse(&raw_message)
            .expect("should parse as a valid message");

        assert_eq!(parsed.subject(), Some("Test"));
        assert_eq!(parsed.body_text(0).as_deref(), Some("Test message.\r\n"));
    }
}
