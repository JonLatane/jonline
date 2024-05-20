use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{federated_profiles, federated_users};

pub fn federate_profile(
    request: FederatedUser,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<FederatedUser, Status> {
    // validate_permission(&Some(user), Permission::FederateProfile)?;

    let fake_response = request.clone();
    let remote_user_id = &request.user_id;
    let server_host = &request.host;

    // upsert the federated user
    diesel::insert_into(federated_users::table)
        .values(models::NewFederatedUser {
            remote_user_id: remote_user_id.to_string(),
            server_host: server_host.to_string(),
        })
        .on_conflict_do_nothing()
        .execute(conn)
        .map_err(|_| Status::new(Code::Internal, "data_error"))?;

    let federated_user = federated_users::table
        .select(federated_users::all_columns)
        .filter(federated_users::remote_user_id.eq(remote_user_id))
        .filter(federated_users::server_host.eq(server_host))
        .first::<models::FederatedUser>(conn)
        .map_err(|_| Status::new(Code::NotFound, "federated_user_not_found"))?;

    // upsert the federated profile
    diesel::insert_into(federated_profiles::table)
        .values(models::NewFederatedProfile {
            user_id: user.id,
            federated_user_id: federated_user.id,
        })
        .on_conflict_do_nothing()
        .execute(conn)
        .map_err(|_| Status::new(Code::Internal, "data_error"))?;

    Ok(fake_response)
}
