use std::time::SystemTime;

use diesel::*;
use tonic::{Code, Status};

use super::{Author, AUTHOR_COLUMNS};
use crate::db_connection::PgPooledConnection;
use crate::schema::{ai_model_provider_grants, ai_model_providers, users};

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
#[diesel(table_name = ai_model_providers)]
pub struct AIModelProvider {
    pub id: i64,
    pub user_id: i64,
    pub name: String,
    pub configuration: serde_json::Value,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = ai_model_providers)]
pub struct NewAIModelProvider {
    pub user_id: i64,
    pub name: String,
    pub configuration: serde_json::Value,
}

#[derive(Debug, Queryable, Identifiable, Clone)]
#[diesel(table_name = ai_model_provider_grants)]
pub struct AIModelProviderGrant {
    pub id: i64,
    pub ai_model_provider_id: i64,
    pub grantee_id: i64,
    pub model_names: Vec<String>,
    pub tokens_remaining: i64,
    pub created_at: SystemTime,
    pub updated_at: Option<SystemTime>,
    // How far a single `GenerateMedia` call's actual token usage overshot `tokens_remaining` the
    // moment it hit 0 -- see `AIModelProviderGrant.overage`'s own proto doc, and
    // `rpcs::ai_model_providers::generate_media`'s own spend logic.
    pub overage: i64,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = ai_model_provider_grants)]
pub struct NewAIModelProviderGrant {
    pub ai_model_provider_id: i64,
    pub grantee_id: i64,
    pub model_names: Vec<String>,
    pub tokens_remaining: i64,
    // Always 0 for a fresh grant -- see `AIModelProviderGrant.overage`'s own doc. Included here
    // (rather than relying on the column's own DB default) since `GrantAIModelProvider`'s upsert
    // needs to reset it back to 0 on conflict too (a repeat grant clears any prior debt), and an
    // `ON CONFLICT DO UPDATE SET` only touches columns actually present in `.set()`.
    pub overage: i64,
}

pub fn get_ai_model_provider(id: i64, conn: &mut PgPooledConnection) -> Result<AIModelProvider, Status> {
    ai_model_providers::table
        .filter(ai_model_providers::id.eq(id))
        .first::<AIModelProvider>(conn)
        .map_err(|_| Status::new(Code::NotFound, "ai_model_provider_not_found"))
}

/// Every AIModelProvider owned by any of `user_ids`, paired with each owner's `Author` -- batched
/// so callers marshaling many users at once (e.g. `get_users.rs`'s `attach_available_ai_models`,
/// or `get_ai_model_providers.rs` with a single-element slice) never issue one query per user.
pub fn get_ai_model_providers_for_users(
    user_ids: &[i64],
    conn: &mut PgPooledConnection,
) -> Result<Vec<(AIModelProvider, Author)>, Status> {
    if user_ids.is_empty() {
        return Ok(vec![]);
    }
    ai_model_providers::table
        .inner_join(users::table)
        .select((ai_model_providers::all_columns, AUTHOR_COLUMNS))
        .filter(ai_model_providers::user_id.eq_any(user_ids))
        .order(ai_model_providers::created_at.asc())
        .load::<(AIModelProvider, Author)>(conn)
        .map_err(|e| {
            log::error!("Failed to load AI model providers for users {:?}: {:?}", user_ids, e);
            Status::new(Code::Internal, "failed_to_load_ai_model_providers")
        })
}

/// Every grant on any of `provider_ids`, paired with each grantee's `Author` -- batched variant of
/// what used to be a single-provider-at-a-time loader.
pub fn get_ai_model_provider_grants_for_providers(
    provider_ids: &[i64],
    conn: &mut PgPooledConnection,
) -> Result<Vec<(AIModelProviderGrant, Author)>, Status> {
    if provider_ids.is_empty() {
        return Ok(vec![]);
    }
    ai_model_provider_grants::table
        .inner_join(users::table.on(users::id.eq(ai_model_provider_grants::grantee_id)))
        .select((ai_model_provider_grants::all_columns, AUTHOR_COLUMNS))
        .filter(ai_model_provider_grants::ai_model_provider_id.eq_any(provider_ids))
        .order(ai_model_provider_grants::created_at.asc())
        .load::<(AIModelProviderGrant, Author)>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load AI model provider grants for providers {:?}: {:?}",
                provider_ids,
                e
            );
            Status::new(Code::Internal, "failed_to_load_ai_model_provider_grants")
        })
}

/// Every grant made *to* any of `grantee_ids`, on any provider (their own or someone else's),
/// paired with that grant's `AIModelProvider` and its owner's `Author` -- used to build
/// [`AvailableAIModel`](#jonline-AvailableAIModel)s for `User.available_ai_models`/
/// `GetAIModelProvidersResponse.available_ai_models`. Batched variant of what used to be a
/// single-grantee-at-a-time loader.
pub fn get_ai_model_provider_grants_for_grantees(
    grantee_ids: &[i64],
    conn: &mut PgPooledConnection,
) -> Result<Vec<(AIModelProviderGrant, AIModelProvider, Author)>, Status> {
    if grantee_ids.is_empty() {
        return Ok(vec![]);
    }
    ai_model_provider_grants::table
        .inner_join(ai_model_providers::table.on(ai_model_providers::id.eq(ai_model_provider_grants::ai_model_provider_id)))
        .inner_join(users::table.on(users::id.eq(ai_model_providers::user_id)))
        .select((
            ai_model_provider_grants::all_columns,
            ai_model_providers::all_columns,
            AUTHOR_COLUMNS,
        ))
        .filter(ai_model_provider_grants::grantee_id.eq_any(grantee_ids))
        .order(ai_model_provider_grants::created_at.asc())
        .load::<(AIModelProviderGrant, AIModelProvider, Author)>(conn)
        .map_err(|e| {
            log::error!(
                "Failed to load AI model provider grants for grantees {:?}: {:?}",
                grantee_ids,
                e
            );
            Status::new(Code::Internal, "failed_to_load_ai_model_provider_grants")
        })
}

/// Grants (or resets) `grantee_id`'s access to `ai_model_provider_id`, upserting on the unique
/// `(ai_model_provider_id, grantee_id)` pair -- see `GrantAIModelProvider`'s RPC doc on why calling
/// this again *replaces* rather than adds to `tokens_remaining`.
pub fn upsert_ai_model_provider_grant(
    new_grant: &NewAIModelProviderGrant,
    conn: &mut PgPooledConnection,
) -> Result<AIModelProviderGrant, Status> {
    insert_into(ai_model_provider_grants::table)
        .values(new_grant)
        .on_conflict((
            ai_model_provider_grants::ai_model_provider_id,
            ai_model_provider_grants::grantee_id,
        ))
        .do_update()
        .set((
            ai_model_provider_grants::model_names.eq(&new_grant.model_names),
            ai_model_provider_grants::tokens_remaining.eq(new_grant.tokens_remaining),
            // A (re-)grant always clears any prior debt -- see `AIModelProviderGrant.overage`'s
            // own doc.
            ai_model_provider_grants::overage.eq(new_grant.overage),
            ai_model_provider_grants::updated_at.eq(SystemTime::now()),
        ))
        .get_result::<AIModelProviderGrant>(conn)
        .map_err(|e| {
            log::error!("Failed to grant AI model provider access: {:?}", e);
            Status::new(Code::Internal, "failed_to_grant_ai_model_provider")
        })
}

/// Deletes the grant on `ai_model_provider_id` for `grantee_id`, if any. Not an error if none exists.
pub fn delete_ai_model_provider_grant(
    ai_model_provider_id: i64,
    grantee_id: i64,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    delete(
        ai_model_provider_grants::table
            .filter(ai_model_provider_grants::ai_model_provider_id.eq(ai_model_provider_id))
            .filter(ai_model_provider_grants::grantee_id.eq(grantee_id)),
    )
    .execute(conn)
    .map_err(|e| {
        log::error!("Failed to revoke AI model provider access: {:?}", e);
        Status::new(Code::Internal, "failed_to_revoke_ai_model_provider")
    })?;
    Ok(())
}

/// Deletes every grant on `ai_model_provider_id` -- called before deleting the provider itself.
pub fn delete_ai_model_provider_grants(
    ai_model_provider_id: i64,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    delete(ai_model_provider_grants::table.filter(ai_model_provider_grants::ai_model_provider_id.eq(ai_model_provider_id)))
        .execute(conn)
        .map_err(|e| {
            log::error!(
                "Failed to delete grants for AI model provider {}: {:?}",
                ai_model_provider_id,
                e
            );
            Status::new(Code::Internal, "failed_to_delete_ai_model_provider_grants")
        })?;
    Ok(())
}
