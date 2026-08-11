use crate::schema::server_configurations::dsl::*;
use crate::{db_connection::PgPooledConnection, protos::Permission};
use diesel::*;
use tonic::{Code, Status};

use crate::{
    marshaling::*, models, protos, rpcs::get_server_configuration_model, rpcs::validations::*,
};

pub fn configure_server(
    request: protos::ServerConfiguration,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<protos::ServerConfiguration, Status> {
    log::info!("ConfigureServer called; request {:?}", request);
    validate_permission(&Some(user), Permission::Admin)?;
    validate_configuration(&request)?;

    let mut new_config = request.to_db();
    // `FacebookAuthConfig.app_secret` is write-only -- `to_proto` always blanks it before it
    // reaches a client (see `ToProtoServerConfiguration`), so an empty incoming value means
    // "leave whatever's already stored alone," not "clear it." Setting
    // `federation_info.facebook_auth_config` to `None` entirely is the only way to actually
    // clear a previously-stored secret.
    if let Some(incoming_facebook_auth_config) = request
        .federation_info
        .as_ref()
        .and_then(|f| f.facebook_auth_config.as_ref())
        .filter(|c| c.app_secret.is_empty())
    {
        let existing_secret = get_server_configuration_model(conn)
            .ok()
            .and_then(|c| serde_json::from_value::<protos::FederationInfo>(c.federation_info).ok())
            .and_then(|f| f.facebook_auth_config)
            .map(|c| c.app_secret)
            .unwrap_or_default();
        let mut merged_federation_info: protos::FederationInfo =
            serde_json::from_value(new_config.federation_info.clone()).unwrap();
        merged_federation_info.facebook_auth_config = Some(protos::FacebookAuthConfig {
            app_id: incoming_facebook_auth_config.app_id.clone(),
            app_secret: existing_secret,
        });
        new_config.federation_info = serde_json::to_value(merged_federation_info).unwrap();
    }

    let result =
        conn.transaction::<models::ServerConfiguration, diesel::result::Error, _>(|conn| {
            update(server_configurations)
                .set(active.eq(false))
                .execute(conn)?;
            let configuration = insert_into(server_configurations)
                .values(&new_config)
                .get_result::<models::ServerConfiguration>(conn)?;
            Ok(configuration)
        });
    match result {
        Ok(configuration) => {
            log::info!(
                "ConfigureServer called; updated configuration to {:?}",
                configuration.to_proto()
            );
            Ok(configuration.to_proto())
        }
        Err(e) => {
            log::error!("ConfigureServer failed. Error: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating"))
        }
    }
}
