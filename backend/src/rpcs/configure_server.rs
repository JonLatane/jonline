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
    conn: &PgPooledConnection,
) -> Result<Response<protos::ServerConfiguration>, Status> {
    println!("ConfigureServer called; request {:?}", request);
    validate_configuration(&request)?;

    if !user.has_permission(protos::Permission::Admin) {
        return Err(Status::new(Code::PermissionDenied, "not_admin"));
    }
    let result = conn.transaction::<models::ServerConfiguration, diesel::result::Error, _>(|| {
        update(server_configurations).set(active.eq(false)).execute(conn)?;
        let configuration = insert_into(server_configurations)
            .values(request.to_db())
            .get_result::<models::ServerConfiguration>(conn)?;
        Ok(configuration)
    });
    match result {
        Ok(configuration) => {
            println!("ConfigureServer called; updated configuration to {:?}", configuration.to_proto());
            Ok(Response::new(configuration.to_proto()))},
        Err(e) => {
            println!("ConfigureServer failed. Error: {:?}", e);
            Err(Status::new(Code::Internal, "error_updating"))},
    }
//     let server_configuration = server_configurations
//         .filter(active.eq(true))
//         .first::<models::ServerConfiguration>(conn);
//     match server_configuration {
//         Ok(server_configuration) => {
//             let result = server_configuration.to_proto();
//             println!("GetServerConfiguration called, returning {:?}", result);
//             Ok(Response::new(result))
//         }
//         Err(diesel::NotFound) => {
//             let result = match insert_into(server_configurations)
//                 .values(default_server_configuration())
//                 .get_result::<models::ServerConfiguration>(conn) {
//                 Ok(server_configuration) => server_configuration.to_proto(),
//                 Err(e) => {
//                     println!("Error inserting default server configuration: {:?}", e);
//                     return Err(Status::new(Code::Internal, "error_inserting_default_server_configuration"));
//                 }
//             };
//             println!(
//                 "GetServerConfiguration called, generated new one: {:?}",
//                 result
//             );
//             Ok(Response::new(result))
//         }
//         Err(e) => {
//             println!("GetServerConfiguration error: {:?}", e);
//             Err(Status::new(Code::Unauthenticated, "data_error"))
//         }
//     }
}
