use std::time::{Duration, SystemTime};

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::schema::users;

/// Codes expire 10 minutes after `StartContactMethodVerification` sent them -- see this RPC's own
/// doc in `rellm.proto`.
const CODE_TTL: Duration = Duration::from_secs(10 * 60);
/// Caps brute-force guesses against a 6-digit code (1M combinations) within its TTL window -- see
/// `ContactMethodVerification.attempts`'s own doc.
const MAX_ATTEMPTS: i32 = 5;

/// Verifies a code sent by `StartContactMethodVerification` against `current_user`'s own `phone`
/// `ContactMethod` -- see this RPC's own doc in `rellm.proto`.
pub fn verify_contact_method(
    request: VerifyContactMethodRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<ContactMethod, Status> {
    if request.value.starts_with("mailto:") {
        return Err(Status::new(
            Code::Unimplemented,
            "email_verification_not_implemented",
        ));
    }
    if !request.value.starts_with("tel:") {
        return Err(Status::new(
            Code::InvalidArgument,
            "value_must_be_a_tel_or_mailto_url",
        ));
    }

    let mut phone: ContactMethod = current_user
        .phone
        .to_owned()
        .and_then(|v| serde_json::from_value::<ContactMethod>(v).ok())
        .filter(|cm| cm.value.as_deref() == Some(request.value.as_str()))
        .ok_or_else(|| Status::new(Code::FailedPrecondition, "phone_not_set"))?;

    let mut verification = phone
        .verification_in_progress
        .clone()
        .ok_or_else(|| Status::new(Code::FailedPrecondition, "no_verification_in_progress"))?;

    let started_at: SystemTime = verification
        .verification_started_at
        .as_ref()
        .map(|t| t.to_db())
        .unwrap_or(SystemTime::UNIX_EPOCH);
    if started_at + CODE_TTL < SystemTime::now() {
        // Expired -- clear it so a stale code can't be reused, and require a fresh
        // `StartContactMethodVerification` call.
        phone.verification_in_progress = None;
        persist_phone(conn, current_user.id, &phone)?;
        return Err(Status::new(Code::FailedPrecondition, "verification_expired"));
    }

    if verification.attempts >= MAX_ATTEMPTS {
        phone.verification_in_progress = None;
        persist_phone(conn, current_user.id, &phone)?;
        return Err(Status::new(Code::FailedPrecondition, "too_many_attempts"));
    }

    if request.code != verification.verification_code {
        verification.attempts += 1;
        phone.verification_in_progress = Some(verification);
        persist_phone(conn, current_user.id, &phone)?;
        return Err(Status::new(Code::InvalidArgument, "incorrect_code"));
    }

    phone.verified_at = Some(SystemTime::now().to_proto());
    phone.verification_in_progress = None;
    persist_phone(conn, current_user.id, &phone)?;

    Ok(phone)
}

fn persist_phone(
    conn: &mut PgPooledConnection,
    user_id: i64,
    phone: &ContactMethod,
) -> Result<(), Status> {
    diesel::update(users::table)
        .filter(users::id.eq(user_id))
        .set(users::phone.eq(serde_json::to_value(phone).unwrap()))
        .execute(conn)
        .map(|_| ())
        .map_err(|e| {
            log::error!("Failed to persist phone verification state: {:?}", e);
            Status::new(Code::Internal, "data_error")
        })
}
