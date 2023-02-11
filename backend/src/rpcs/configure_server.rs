use crate::db_connection::PgPooledConnection;
use crate::schema::server_configurations::dsl::*;
use diesel::*;
use tonic::{Code, Response, Status};

use crate::{models, protos};
use crate::conversions::*;
use crate::logic::*;
use super::validations::*;

pub fn configure_server(
    request: protos::ServerConfiguration,
    user: models::User,
    conn: &mut PgPooledConnection,
) -> Result<Response<protos::ServerConfiguration>, Status> {
    log::info!("ConfigureServer called; request {:?}", request);
    validate_configuration(&request)?;

    if !user.has_permission(protos::Permission::Admin) {
        return Err(Status::new(Code::PermissionDenied, "not_admin"));
    }
    let result = conn.transaction::<models::ServerConfiguration, diesel::result::Error, _>(|conn| {
        update(server_configurations).set(active.eq(false)).execute(conn)?;
        let configuration = insert_into(server_configurations)
            .values(request.to_db())
            .get_result::<models::ServerConfiguration>(conn)?;
        Ok(configuration)
    });
    match result {
        Ok(configuration) => {
            log::info!("ConfigureServer called; updated configuration to {:?}", configuration.to_proto());
            Ok(Response::new(configuration.to_proto()))},
        Err(e) => {
            log::error!("ConfigureServer failed. Error: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating"))},
    }
}
