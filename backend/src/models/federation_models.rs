use std::time::SystemTime;

// use tonic::{Code, Status};
use diesel::*;

// use crate::db_connection::PgPooledConnection;
use crate::schema::{federated_users, federated_profiles};

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
pub struct FederatedUser {
    pub id: i64,
    pub remote_user_id: String,
    pub server_host: String,
    pub created_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = federated_users)]
pub struct NewFederatedUser {
    pub remote_user_id: String,
    pub server_host: String,
}

#[derive(Debug, Queryable, Identifiable, AsChangeset, Clone)]
pub struct FederatedProfile {
    pub id: i64,
    pub user_id: i64,
    pub federated_user_id: i64,
    pub created_at: SystemTime,
}

#[derive(Debug, Insertable)]
#[diesel(table_name = federated_profiles)]
pub struct NewFederatedProfile {
    pub user_id: i64,
    pub federated_user_id: i64,
}
