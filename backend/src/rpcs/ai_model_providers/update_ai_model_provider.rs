use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;
use crate::schema::ai_model_providers;

pub fn update_ai_model_provider(
    request: AiModelProvider,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<AiModelProvider, Status> {
    validate_permission(&Some(current_user), Permission::CreateAiModelProviders)?;

    let provider_id = request.id.to_db_id_or_err("id")?;
    let mut existing = models::get_ai_model_provider(provider_id, conn)?;

    if existing.user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    let name = request.name.trim();
    if !name.is_empty() {
        existing.name = name.to_string();
    }

    if let Some(provider) = &request.provider {
        match provider {
            ai_model_provider::Provider::GeminiCredentials(credentials) => {
                if credentials
                    .gemini_api_key
                    .as_ref()
                    .map(|key| key.trim().is_empty())
                    .unwrap_or(true)
                {
                    return Err(Status::new(Code::InvalidArgument, "gemini_api_key_required"));
                }
            }
            _ => {
                return Err(Status::new(
                    Code::InvalidArgument,
                    "ai_model_provider_not_yet_supported",
                ));
            }
        }
        existing.configuration = provider_configuration_to_json(&request.provider);
    }
    existing.updated_at = Some(SystemTime::now());

    let updated =
        diesel::update(ai_model_providers::table.filter(ai_model_providers::id.eq(existing.id)))
            .set(&existing)
            .get_result::<models::AIModelProvider>(conn)
            .map_err(|e| {
                log::error!("Failed to update AI model provider: {:?}", e);
                Status::new(Code::Internal, "failed_to_update_ai_model_provider")
            })?;

    let owner = models::get_author(updated.user_id, conn)?;
    let grants = models::get_ai_model_provider_grants_for_providers(&[updated.id], conn)?
        .into_iter()
        .map(|(grant, grantee)| MarshalableAIModelProviderGrant(grant, grantee).to_proto())
        .collect();

    Ok(MarshalableAIModelProvider(updated, owner, grants).to_proto())
}
