use tonic::Status;

use crate::db_connection::PgPooledConnection;
use crate::models;
use crate::protos::*;

pub fn get_push_subscription_status(
    request: GetPushSubscriptionStatusRequest,
    user: &models::User,
    conn: &mut PgPooledConnection,
) -> Result<GetPushSubscriptionStatusResponse, Status> {
    let registered = models::push_subscription_exists(user.id, &request.endpoint, conn)?;
    Ok(GetPushSubscriptionStatusResponse { registered })
}
