use crate::schema::server_configurations::dsl::*;
use crate::{db_connection::PgPooledConnection, protos::Permission};
use diesel::*;
use tonic::{Code, Status};

use crate::{marshaling::*, models, protos, rpcs::validations::*};

pub fn configure_server(
    request: protos::ServerConfiguration,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<protos::ServerConfiguration, Status> {
    log::info!("ConfigureServer called; request {:?}", request);
    validate_permission(&Some(user), Permission::Admin)?;
    validate_configuration(&request)?;

    let result =
        conn.transaction::<models::ServerConfiguration, diesel::result::Error, _>(|conn| {
            update(server_configurations)
                .set(active.eq(false))
                .execute(conn)?;
            let configuration = insert_into(server_configurations)
                .values(request.to_db())
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
