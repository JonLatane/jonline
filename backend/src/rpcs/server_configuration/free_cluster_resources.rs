use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::rpcs::server_configuration::lock_cluster_resources::validate_conductor;
use crate::schema::server_configurations::dsl as scd;
use crate::{models, protos};

/// Releases `request.resources` previously locked by `request.namespace_id` via
/// `LockClusterResources`. A no-op for any resource `request.namespace_id` doesn't currently
/// hold -- see `FreeClusterResourcesRequest`'s own doc in server_configuration.proto. Same
/// conductor/shared-secret validation, and same in-place (not versioned) update, as
/// `lock_cluster_resources`.
pub fn free_cluster_resources(
    request: protos::FreeClusterResourcesRequest,
    shared_secret: &str,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    log::info!("FreeClusterResources called: {:?}", request);

    let config = scd::server_configurations
        .filter(scd::active.eq(true))
        .first::<models::ServerConfiguration>(conn)
        .map_err(|_| Status::new(Code::Internal, "data_error"))?;
    validate_conductor(&config, shared_secret)?;

    let result = conn.transaction::<(), diesel::result::Error, _>(|conn| {
        let config = scd::server_configurations
            .filter(scd::active.eq(true))
            .for_update()
            .first::<models::ServerConfiguration>(conn)?;
        let mut resources: protos::ClusterResources =
            serde_json::from_value(config.cluster_resources.clone().unwrap_or_default())
                .unwrap_or_default();
        let mut conductor_state = resources.conductor_state.clone().unwrap_or_default();

        let held_by_caller = conductor_state
            .browser_lock_holder
            .as_deref()
            .is_some_and(|holder| holder == request.namespace_id);
        if held_by_caller {
            conductor_state.browser_lock_holder = None;
            resources.conductor_state = Some(conductor_state);
            update(scd::server_configurations.filter(scd::id.eq(config.id)))
                .set(scd::cluster_resources.eq(serde_json::to_value(&resources).unwrap()))
                .execute(conn)?;
        }

        Ok(())
    });

    match result {
        Ok(()) => Ok(()),
        Err(e) => {
            log::error!("FreeClusterResources failed: {:?}", e);
            Err(Status::new(Code::Internal, "data_error"))
        }
    }
}
