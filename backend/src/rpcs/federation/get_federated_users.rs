use diesel::*;
// use tonic::{Code, Status};

use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;
use crate::schema::{federated_profiles, federated_users};

pub fn get_federated_users(
    user_id: i64,
    conn: &mut PgPooledConnection,
) -> Vec<FederatedAccount> {
    federated_users::table
        .inner_join(
            federated_profiles::table
                .on(federated_profiles::federated_user_id.eq(federated_users::id)),
        )
        .select(federated_users::all_columns)
        .filter(federated_profiles::user_id.eq(user_id))
        .load::<models::FederatedUser>(conn)
        .unwrap()
        .iter()
        .map(|user| FederatedAccount {
            host: user.server_host.clone(),
            user_id: user.remote_user_id.clone(),
        })
        .collect()
}
