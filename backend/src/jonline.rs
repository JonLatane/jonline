use crate::protos::*;
use jonline_server::Jonline;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::db_connection::*;
use crate::rpcs;

pub struct JonLineImpl {
    pub pool: PgPool,
}

impl Clone for JonLineImpl {
    fn clone(&self) -> Self {
        JonLineImpl {
            pool: establish_pool(),
        }
    }
}

#[tonic::async_trait]
impl Jonline for JonLineImpl {
    async fn get_service_version(
        &self,
        _request: Request<()>,
    ) -> Result<Response<GetServiceVersionResponse>, Status> {
        rpcs::get_service_version()
    }

    async fn create_account(
        &self,
        request: Request<CreateAccountRequest>,
    ) -> Result<Response<AuthTokenResponse>, Status> {
        let conn = match get_connection(&self.pool) {
            Err(e) => return Err(e),
            Ok(conn) => conn,
        };
        rpcs::create_account(request, &conn)
    }

    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<AuthTokenResponse>, Status> {
        let conn = match get_connection(&self.pool) {
            Err(e) => return Err(e),
            Ok(conn) => conn,
        };
        rpcs::login(request, &conn)
    }

    async fn refresh_token(&self, request: Request<RefreshTokenRequest>) -> Result<Response<ExpirableToken>, Status> {
        let conn = match get_connection(&self.pool) {
            Err(e) => return Err(e),
            Ok(conn) => conn,
        };
        rpcs::refresh_token(request, &conn)
    }

    async fn get_current_user(&self, request: Request<()>) -> Result<Response<User>, Status> {
        let conn = match get_connection(&self.pool) {
            Err(e) => return Err(e),
            Ok(conn) => conn,
        };
        match auth::get_current_user(&request, &conn) {
            Err(e) => Err(e),
            Ok(user) => rpcs::get_current_user(user),
        }
    }

    async fn get_post(&self, request: Request<GetPostRequest>) -> Result<Response<Post>, Status> {
        let conn = match get_connection(&self.pool) {
            Err(e) => return Err(e),
            Ok(conn) => conn,
        };
        match auth::get_current_user(&request, &conn) {
            Err(e) => Err(e),
            Ok(_user) => rpcs::get_post(request, &conn),
        }
       
    }
}

fn get_connection(pool: &PgPool) -> Result<PgPooledConnection, Status> {
    match pool.get() {
        Err(_) => Err(Status::new(Code::DataLoss, "database_connection_failure")),
        Ok(conn) => Ok(conn),
    }
}
