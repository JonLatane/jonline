use std::collections::HashMap;

use tonic::Status;

use super::{ToProtoAuthor, ToProtoId, ToProtoTime};
use crate::db_connection::PgPooledConnection;
use crate::logic::{capabilities_for_model, models_for_provider};
use crate::models;
use crate::protos::*;

#[derive(Debug, Clone)]
pub struct MarshalableAIModelProvider(
    pub models::AIModelProvider,
    pub models::Author,
    pub Vec<AiModelProviderGrant>,
);

pub trait ToProtoMarshalableAIModelProvider {
    fn to_proto(&self) -> AiModelProvider;
}

impl ToProtoMarshalableAIModelProvider for MarshalableAIModelProvider {
    fn to_proto(&self) -> AiModelProvider {
        let provider = &self.0;
        let owner = &self.1;
        let grants = &self.2;
        AiModelProvider {
            id: provider.id.to_proto_id(),
            owner: Some(owner.to_proto(None)),
            name: provider.name.clone(),
            provider: provider_configuration_to_proto(&provider.configuration),
            grants: grants.clone(),
            created_at: Some(provider.created_at.to_proto()),
            updated_at: provider.updated_at.map(|t| t.to_proto()),
        }
    }
}

#[derive(Debug, Clone)]
pub struct MarshalableAIModelProviderGrant(pub models::AIModelProviderGrant, pub models::Author);

pub trait ToProtoMarshalableAIModelProviderGrant {
    fn to_proto(&self) -> AiModelProviderGrant;
}

impl ToProtoMarshalableAIModelProviderGrant for MarshalableAIModelProviderGrant {
    fn to_proto(&self) -> AiModelProviderGrant {
        let grant = &self.0;
        let grantee = &self.1;
        AiModelProviderGrant {
            ai_model_provider_id: grant.ai_model_provider_id.to_proto_id(),
            ai_model_grantee: Some(grantee.to_proto(None)),
            model_names: grant.model_names.clone(),
            tokens_remaining: grant.tokens_remaining as u64,
            overage: grant.overage as u64,
            created_at: Some(grant.created_at.to_proto()),
            updated_at: grant.updated_at.map(|t| t.to_proto()),
        }
    }
}

/// Builds every [`AvailableAIModel`](#rellm-AvailableAIModel) for each of `target_user_ids`, plus each target
/// user's own [`AIModelProvider`](#rellm-AIModelProvider)s -- combines, per target user, their own providers
/// (each expanded into every model `logic::models_for_provider` lists for it, `grant: None`, full
/// ungated access) with every [`AIModelProviderGrant`](#rellm-AIModelProviderGrant) made *to* them (each expanded
/// into the model(s) it actually covers -- `grant.model_names`, or the provider's full catalog if
/// that list is empty). A target user can never end up with both an owned entry and a granted entry
/// for the same provider -- `grant_ai_model_provider.rs` rejects granting yourself access to your
/// own provider.
///
/// Batched across `target_user_ids` in a fixed number of queries regardless of how many users are
/// being marshaled -- used by both `get_users.rs`'s `attach_advanced_admin_data` (many users at
/// once) and `get_ai_model_providers.rs` (a single-element slice, so the two RPCs share this exact
/// logic instead of duplicating it).
pub fn build_available_ai_models_for_users(
    target_user_ids: &[i64],
    conn: &mut PgPooledConnection,
) -> Result<HashMap<i64, (Vec<AiModelProvider>, Vec<AvailableAiModel>)>, Status> {
    let mut result: HashMap<i64, (Vec<AiModelProvider>, Vec<AvailableAiModel>)> = target_user_ids
        .iter()
        .map(|id| (*id, (vec![], vec![])))
        .collect();
    if target_user_ids.is_empty() {
        return Ok(result);
    }

    // Each target user's own providers, expanded into every model they support.
    let owned = models::get_ai_model_providers_for_users(target_user_ids, conn)?;
    let owned_provider_ids: Vec<i64> = owned.iter().map(|(provider, _)| provider.id).collect();
    let grants_on_owned = models::get_ai_model_provider_grants_for_providers(&owned_provider_ids, conn)?;
    let mut grants_by_provider_id: HashMap<i64, Vec<AiModelProviderGrant>> = HashMap::new();
    for (grant, grantee) in grants_on_owned {
        grants_by_provider_id
            .entry(grant.ai_model_provider_id)
            .or_default()
            .push(MarshalableAIModelProviderGrant(grant, grantee).to_proto());
    }
    for (provider, owner) in &owned {
        let grants = grants_by_provider_id.get(&provider.id).cloned().unwrap_or_default();
        let provider_proto = MarshalableAIModelProvider(provider.clone(), owner.clone(), grants).to_proto();
        if let Some(entry) = result.get_mut(&provider.user_id) {
            for model in models_for_provider(&provider_proto.provider) {
                entry.1.push(AvailableAiModel {
                    model_name: model.name.to_string(),
                    capabilities: model.capabilities.iter().map(|c| *c as i32).collect(),
                    grant: None,
                    provider: Some(provider_proto.clone()),
                });
            }
            entry.0.push(provider_proto);
        }
    }

    // Access granted *to* each target user, on any provider (their own or someone else's).
    let granted = models::get_ai_model_provider_grants_for_grantees(target_user_ids, conn)?;
    let grantee_authors: HashMap<i64, models::Author> = models::get_authors(target_user_ids, conn)
        .into_iter()
        .map(|author| (author.id, author))
        .collect();
    for (grant, provider, provider_owner) in granted {
        let grantee_id = grant.grantee_id;
        let Some(grantee_author) = grantee_authors.get(&grantee_id) else {
            continue;
        };
        // Its own `grants` list is left empty here -- a mere grantee shouldn't see who else has
        // been granted access to a provider they don't own (see `AvailableAIModel`'s own doc).
        let provider_proto = MarshalableAIModelProvider(provider.clone(), provider_owner.clone(), vec![]).to_proto();
        let model_names: Vec<String> = if grant.model_names.is_empty() {
            models_for_provider(&provider_proto.provider)
                .iter()
                .map(|m| m.name.to_string())
                .collect()
        } else {
            grant.model_names.clone()
        };
        let grant_proto = MarshalableAIModelProviderGrant(grant, grantee_author.clone()).to_proto();
        if let Some(entry) = result.get_mut(&grantee_id) {
            for model_name in model_names {
                let capabilities = capabilities_for_model(&provider_proto.provider, &model_name)
                    .iter()
                    .map(|c| *c as i32)
                    .collect();
                entry.1.push(AvailableAiModel {
                    model_name,
                    capabilities,
                    grant: Some(grant_proto.clone()),
                    provider: Some(provider_proto.clone()),
                });
            }
        }
    }

    Ok(result)
}

/// `configuration` JSONB shape, one top-level tagged key per external service (mirroring the proto
/// `oneof provider`'s variants): `{"gemini_credentials": {"gemini_api_key": "..."}}`,
/// `{"openai_credentials": {"openai_api_key": "..."}}`, `{"anthropic_credentials":
/// {"anthropic_api_key": "..."}}`. The actual key/secret is intentionally never surfaced back here
/// -- see `GeminiCredentials.gemini_api_key`'s own doc comment.
pub fn provider_configuration_to_proto(
    configuration: &serde_json::Value,
) -> Option<ai_model_provider::Provider> {
    if configuration.get("gemini_credentials").is_some() {
        return Some(ai_model_provider::Provider::GeminiCredentials(
            GeminiCredentials { gemini_api_key: None },
        ));
    }
    if configuration.get("openai_credentials").is_some() {
        return Some(ai_model_provider::Provider::OpenaiCredentials(
            OpenAiCredentials {
                openai_api_key: None,
            },
        ));
    }
    if configuration.get("anthropic_credentials").is_some() {
        return Some(ai_model_provider::Provider::AnthropicCredentials(
            AnthropicCredentials {
                anthropic_api_key: None,
            },
        ));
    }
    if configuration.get("digitalocean_credentials").is_some() {
        return Some(ai_model_provider::Provider::DigitaloceanCredentials(
            DigitalOceanCredentials {
                digitalocean_api_key: None,
            },
        ));
    }
    None
}

/// Reads the real Gemini API key back out of a provider's `configuration` column -- the one place
/// this ever leaves the database, used only server-side (by `rpcs::ai_model_providers::generate_media`
/// to actually call Gemini) and never included in a response (see `provider_configuration_to_proto`,
/// which always sends `gemini_api_key: None`).
pub fn gemini_api_key_from_configuration(configuration: &serde_json::Value) -> Option<String> {
    configuration
        .get("gemini_credentials")?
        .get("gemini_api_key")?
        .as_str()
        .map(str::to_string)
        .filter(|key| !key.trim().is_empty())
}

/// `gemini_api_key_from_configuration`'s counterpart for `OpenAICredentials` -- same reasoning,
/// used by `rpcs::ai_model_providers::generate_media` to actually call OpenAI's Images API.
pub fn openai_api_key_from_configuration(configuration: &serde_json::Value) -> Option<String> {
    configuration
        .get("openai_credentials")?
        .get("openai_api_key")?
        .as_str()
        .map(str::to_string)
        .filter(|key| !key.trim().is_empty())
}

/// `gemini_api_key_from_configuration`'s counterpart for `DigitalOceanCredentials` -- same
/// reasoning, used by `rpcs::ai_model_providers::generate_media` to actually call DigitalOcean's
/// Serverless Inference API.
pub fn digitalocean_api_key_from_configuration(configuration: &serde_json::Value) -> Option<String> {
    configuration
        .get("digitalocean_credentials")?
        .get("digitalocean_api_key")?
        .as_str()
        .map(str::to_string)
        .filter(|key| !key.trim().is_empty())
}

/// The reverse of `provider_configuration_to_proto` -- builds the `configuration` column value
/// (with the real key/secret included) from a request's `oneof provider`. Used by
/// `create_ai_model_provider`/`update_ai_model_provider`.
pub fn provider_configuration_to_json(
    configuration: &Option<ai_model_provider::Provider>,
) -> serde_json::Value {
    match configuration {
        Some(ai_model_provider::Provider::GeminiCredentials(credentials)) => {
            serde_json::json!({ "gemini_credentials": { "gemini_api_key": credentials.gemini_api_key.clone().unwrap_or_default() } })
        }
        Some(ai_model_provider::Provider::OpenaiCredentials(credentials)) => {
            serde_json::json!({ "openai_credentials": { "openai_api_key": credentials.openai_api_key.clone().unwrap_or_default() } })
        }
        Some(ai_model_provider::Provider::AnthropicCredentials(credentials)) => {
            serde_json::json!({ "anthropic_credentials": { "anthropic_api_key": credentials.anthropic_api_key.clone().unwrap_or_default() } })
        }
        Some(ai_model_provider::Provider::DigitaloceanCredentials(credentials)) => {
            serde_json::json!({ "digitalocean_credentials": { "digitalocean_api_key": credentials.digitalocean_api_key.clone().unwrap_or_default() } })
        }
        None => serde_json::json!({}),
    }
}
