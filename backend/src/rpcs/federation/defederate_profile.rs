use diesel::*;
use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{federated_profiles, federated_users};

pub fn defederate_profile(
    request: FederatedAccount,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    // validate_permission(&Some(user), Permission::FederateProfile)?;

    let remote_user_id = &request.user_id;
    let server_host = &request.host;

    let federated_user = match federated_users::table
        .select(federated_users::all_columns)
        .filter(federated_users::remote_user_id.eq(remote_user_id))
        .filter(federated_users::server_host.eq(server_host))
        .first::<models::FederatedUser>(conn)
    {
        Ok(federated_user) => federated_user,
        Err(_) => return Ok(()),
    };

    diesel::delete(federated_profiles::table)
        .filter(federated_profiles::user_id.eq(user.id))
        .filter(federated_profiles::federated_user_id.eq(federated_user.id))
        .execute(conn)
        .map_err(|_| Status::new(Code::Internal, "data_error"))?;

    Ok(())
}
