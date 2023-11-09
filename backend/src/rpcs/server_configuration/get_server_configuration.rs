use crate::db_connection::PgPooledConnection;
use crate::models::default_server_configuration;
use crate::schema::server_configurations::dsl::*;
use diesel::*;
use tonic::{Code, Status};

use crate::marshaling::ToProtoServerConfiguration;
use crate::{models, protos};

pub fn get_server_configuration(
    _request: (), 
    _user: &Option<&models::User>,
    conn: &mut PgPooledConnection,
) -> Result<protos::ServerConfiguration, Status> {
    log::info!("GetServerConfiguration called");
    let result = get_server_configuration_proto(conn)?;
    // log::info!("GetServerConfiguration called, returning {:?}", result);
    Ok(result)
}

pub fn get_server_configuration_proto(
    conn: &mut PgPooledConnection,
) -> Result<protos::ServerConfiguration, Status> {
    Ok(get_server_configuration_model(conn)?.to_proto())
}


pub fn get_server_configuration_model(
    conn: &mut PgPooledConnection,
) -> Result<models::ServerConfiguration, Status> {
    let server_configuration = server_configurations
        .filter(active.eq(true))
        .first::<models::ServerConfiguration>(conn);
    // log::info!(
    //     "GetServerConfiguration called, found {:?}",
    //     server_configuration
    // );
    match server_configuration {
        Ok(sc) => Ok(sc),
        Err(diesel::NotFound) => {
            let result = create_default_server_configuration(conn);
            log::warn!(
                "get_server_configuration_model diesel::NotFound error {:?}",
                result
            );
            result
        }
        Err(e) => {
            log::error!("get_server_configuration_model error: {:?}", e);
            Err(Status::new(Code::Unauthenticated, "data_error"))
        }
    }
}

pub fn create_default_server_configuration(
    conn: &mut PgPooledConnection,
) -> Result<models::ServerConfiguration, Status> {
    let result = match insert_into(server_configurations)
        .values(default_server_configuration())
        .get_result::<models::ServerConfiguration>(conn)
    {
        Ok(server_configuration) => server_configuration,
        Err(e) => {
            log::error!("Error inserting default server configuration: {:?}", e);
            return Err(Status::new(
                Code::Internal,
                "error_inserting_default_server_configuration",
            ));
        }
    };
    Ok(result)
}
