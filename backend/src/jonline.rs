use crate::protos::*;
use jonline_server::Jonline;
use tonic::{Request, Response, Status, Code};

use crate::rpcs;
use crate::db_connection::*;

pub struct JonLineImpl {
    pub pool: PgPool
}

impl Clone for JonLineImpl {
    fn clone(&self) -> Self {
        JonLineImpl {
            pool: establish_pool()
        }
    }
}

#[tonic::async_trait]
impl Jonline for JonLineImpl {
    async fn get_service_version(
        &self,
        request: Request<()>,
    ) -> Result<Response<GetServiceVersionResponse>, Status> {
        rpcs::get_service_version(&self.pool, request)
    }

    async fn get_post(
        &self,
        request: Request<GetPostRequest>,
    ) -> Result<Response<Post>, Status> {
        let conn = match get_connection(&self.pool) {
            Err(e) => return Err(e),
            Ok(conn)  => conn
        };
        rpcs::get_post(&conn, request)
    }
}

fn get_connection(pool: &PgPool) -> Result<PgPooledConnection, Status> {
    match pool.get() {
        Err(_) => Err(Status::new(Code::DataLoss, "DB connection error")),
        Ok(conn) => Ok(conn)
    }
}
