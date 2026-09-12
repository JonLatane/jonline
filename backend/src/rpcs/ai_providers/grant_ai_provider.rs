use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;

/// *Owner-only, no Admin override* -- see the RPC's own doc comment in `ai_providers.proto`
/// for why: an Admin may manage the provider record itself, but only its owner may hand out access
/// to it.
pub fn grant_ai_provider(
    request: GrantAiProviderRequest,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<AiProviderGrant, Status> {
    let provider_id = request
        .ai_provider_id
        .to_db_id_or_err("ai_provider_id")?;
    let provider = models::get_ai_provider(provider_id, conn)?;

    if provider.user_id != current_user.id {
        return Err(Status::new(
            Code::PermissionDenied,
            "ai_provider_owner_required",
        ));
    }

    let grantee_id = request.user_id.to_db_id_or_err("user_id")?;
    if grantee_id == provider.user_id {
        return Err(Status::new(Code::InvalidArgument, "cannot_grant_self"));
    }
    // Ensures the grantee actually exists before creating a grant for them.
    let grantee = models::get_author(grantee_id, conn)?;

    let grant = models::upsert_ai_provider_grant(
        &models::NewAIProviderGrant {
            ai_provider_id: provider.id,
            grantee_id,
            model_names: request.model_names,
            tokens_remaining: request.tokens as i64,
            // A (re-)grant always clears any prior debt -- see `AIProviderGrant.overage`'s
            // own doc.
            overage: 0,
        },
        conn,
    )?;

    Ok(MarshalableAIProviderGrant(grant, grantee).to_proto())
}
