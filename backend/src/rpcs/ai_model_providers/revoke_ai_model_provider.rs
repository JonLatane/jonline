use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;

/// *Owner-only, no Admin override* -- see `grant_ai_model_provider`'s own doc comment.
pub fn revoke_ai_model_provider(
    request: RevokeAiModelProviderRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    let provider_id = request
        .ai_model_provider_id
        .to_db_id_or_err("ai_model_provider_id")?;
    let provider = models::get_ai_model_provider(provider_id, conn)?;

    if provider.user_id != current_user.id {
        return Err(Status::new(
            Code::PermissionDenied,
            "ai_model_provider_owner_required",
        ));
    }

    let grantee_id = request.user_id.to_db_id_or_err("user_id")?;
    models::delete_ai_model_provider_grant(provider.id, grantee_id, conn)
}
