use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;

pub fn unregister_push_subscription(
    request: UnregisterPushSubscriptionRequest,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<(), Status> {
    models::delete_push_subscription(user.id, &request.endpoint, conn)
}
