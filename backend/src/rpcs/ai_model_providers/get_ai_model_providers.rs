use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::marshaling::*;
use crate::models;
use crate::protos::*;
use crate::rpcs::validate_permission;

pub fn get_ai_model_providers(
    request: User,
    current_user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<GetAiModelProvidersResponse, Status> {
    let target_user_id = if request.id.trim().is_empty() {
        current_user.id
    } else {
        request.id.to_db_id_or_err("id")?
    };

    if target_user_id != current_user.id {
        validate_permission(&Some(current_user), Permission::Admin)?;
    }

    // Shared with `get_users.rs`'s `attach_advanced_admin_data` (this is just that same builder
    // called with a single-element slice), so both RPCs stay in sync automatically.
    let mut by_user = build_available_ai_models_for_users(&[target_user_id], conn)?;
    let (providers, available_ai_models) = by_user.remove(&target_user_id).unwrap_or_default();

    Ok(GetAiModelProvidersResponse {
        providers,
        available_ai_models,
    })
}
