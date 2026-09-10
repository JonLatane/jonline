use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::schema::server_configurations::dsl as scd;
use crate::{models, protos};

/// Attempts to acquire `request.resources` on behalf of `request.namespace_id`. Only meaningful
/// when called against the cluster's conductor (this server's own `namespace_id ==
/// conductor_host`); `shared_secret` must match the conductor's own stored
/// `cluster_shared_secret`. See `ClusterResources`/`LockClusterResourcesResponse`'s own docs in
/// server_configuration.proto for the polling contract this expects of callers, and
/// `ClusterConductorState`'s own doc for why this updates the active `server_configurations` row
/// in place (via a `SELECT ... FOR UPDATE`, so two concurrent Lock calls can't both see the lock
/// as free) rather than going through `ConfigureServer`'s usual versioning.
pub fn lock_cluster_resources(
    request: protos::LockClusterResourcesRequest,
    shared_secret: &str,
    conn: &mut PgPooledConnection,
) -> Result<protos::LockClusterResourcesResponse, Status> {
    log::info!("LockClusterResources called: {:?}", request);

    // Validated once up front (a plain read, no row lock needed just to fail fast on a
    // misconfigured/unauthorized caller) before taking the `FOR UPDATE` lock below.
    let config = scd::server_configurations
        .filter(scd::active.eq(true))
        .first::<models::ServerConfiguration>(conn)
        .map_err(|_| Status::new(Code::Internal, "data_error"))?;
    validate_conductor(&config, shared_secret)?;

    let result = conn.transaction::<protos::LockClusterResourcesResponse, diesel::result::Error, _>(
        |conn| {
            let config = scd::server_configurations
                .filter(scd::active.eq(true))
                .for_update()
                .first::<models::ServerConfiguration>(conn)?;
            let mut resources: protos::ClusterResources =
                serde_json::from_value(config.cluster_resources.clone().unwrap_or_default())
                    .unwrap_or_default();
            let mut conductor_state = resources.conductor_state.clone().unwrap_or_default();

            let response = match &conductor_state.browser_lock_holder {
                None => {
                    conductor_state.browser_lock_holder = Some(request.namespace_id.clone());
                    protos::LockClusterResourcesResponse {
                        granted: true,
                        holder: None,
                    }
                }
                Some(holder) if holder == &request.namespace_id => {
                    protos::LockClusterResourcesResponse {
                        granted: true,
                        holder: None,
                    }
                }
                Some(holder) => protos::LockClusterResourcesResponse {
                    granted: false,
                    holder: Some(holder.clone()),
                },
            };

            if response.granted {
                resources.conductor_state = Some(conductor_state);
                update(scd::server_configurations.filter(scd::id.eq(config.id)))
                    .set(scd::cluster_resources.eq(serde_json::to_value(&resources).unwrap()))
                    .execute(conn)?;
            }

            Ok(response)
        },
    );

    match result {
        Ok(response) => Ok(response),
        Err(e) => {
            log::error!("LockClusterResources failed: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    }
}

/// Loads and validates `config.cluster_resources` for a `LockClusterResources`/
/// `FreeClusterResources` call: this server must actually be the conductor, and `shared_secret`
/// must match.
pub(super) fn validate_conductor(
    config: &models::ServerConfiguration,
    shared_secret: &str,
) -> Result<protos::ClusterResources, Status> {
    let cluster_resources: protos::ClusterResources = config
        .cluster_resources
        .clone()
        .and_then(|c| serde_json::from_value(c).ok())
        .ok_or(Status::new(Code::FailedPrecondition, "not_a_conductor"))?;
    if cluster_resources.namespace_id != cluster_resources.conductor_host {
        return Err(Status::new(Code::FailedPrecondition, "not_a_conductor"));
    }
    if shared_secret.is_empty() || shared_secret != cluster_resources.cluster_shared_secret {
        return Err(Status::new(Code::Unauthenticated, "invalid_shared_secret"));
    }
    Ok(cluster_resources)
}
