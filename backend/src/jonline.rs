use crate::models;
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
        let conn = get_connection(&self.pool)?;
        rpcs::create_account(request, &conn)
    }

    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<AuthTokenResponse>, Status> {
        let conn = get_connection(&self.pool)?;
        rpcs::login(request, &conn)
    }

    async fn refresh_token(
        &self,
        request: Request<RefreshTokenRequest>,
    ) -> Result<Response<ExpirableToken>, Status> {
        let conn = get_connection(&self.pool)?;
        rpcs::refresh_token(request, &conn)
    }

    async fn get_current_user(&self, request: Request<()>) -> Result<Response<User>, Status> {
        let conn = get_connection(&self.pool)?;
        match auth::get_auth_user(&request, &conn) {
            Err(e) => Err(e),
            Ok(user) => rpcs::get_current_user(user),
        }
    }
    async fn create_post(
        &self,
        request: Request<CreatePostRequest>,
    ) -> Result<Response<Post>, Status> {
        let conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &conn)?;
        rpcs::create_post(request, user, &conn)
        // match auth::get_auth_user(&request, &conn) {
        //     Err(e) => Err(e),
        //     Ok(user) => rpcs::create_post(request, user, &conn),
        // }
    }

    async fn get_posts(
        &self,
        request: Request<GetPostsRequest>,
    ) -> Result<Response<Posts>, Status> {
        let conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &conn).ok();
        rpcs::get_posts(request, user, &conn)
    }

    async fn query_posts(&self, _request: Request<PostQuery>) -> Result<Response<Posts>, Status> {
        //TODO implement me!
        Ok(Response::new(Posts {
            ..Default::default()
        }))
    }

    async fn get_users(
        &self,
        request: Request<GetUsersRequest>,
    ) -> Result<Response<GetUsersResponse>, Status> {
        let conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &conn).ok();
        rpcs::get_users(request.into_inner(), user, &conn)
    }

    async fn get_groups(&self, request: Request<GetGroupsRequest>) -> Result<Response<GetGroupsResponse>, Status> {
        let conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &conn).ok();
        rpcs::get_groups(request.into_inner(), user, &conn)
    }

    async fn create_group(&self, request: Request<Group>) -> Result<Response<Group>, Status> {
        let conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &conn)?;
        rpcs::create_group(request.into_inner(), user, &conn)
        //TODO implement me!
        // Ok(Response::new(Group {
        //     ..Default::default()
        // }))
    }

    async fn update_group(&self, _request: Request<Group>) -> Result<Response<Group>, Status> {
        //TODO implement me!
        Ok(Response::new(Group {
            ..Default::default()
        }))
    }

    async fn create_membership(&self, _request: Request<Membership>) -> Result<Response<Membership>, Status> {
        //TODO implement me!
        Ok(Response::new(Membership {
            ..Default::default()
        }))
    }

    async fn update_membership(&self, _request: Request<Membership>) -> Result<Response<Membership>, Status> {
        //TODO implement me!
        Ok(Response::new(Membership {
            ..Default::default()
        }))
    }

    async fn get_server_configuration(
        &self,
        _request: Request<()>,
    ) -> Result<Response<ServerConfiguration>, Status> {
        let conn = get_connection(&self.pool)?;
        rpcs::get_server_configuration(&conn)
    }

    async fn configure_server(
        &self,
        request: Request<ServerConfiguration>,
    ) -> Result<Response<ServerConfiguration>, Status> {
        let conn = get_connection(&self.pool)?;
        match auth::get_auth_user(&request, &conn) {
            Err(e) => Err(e),
            Ok(user) => rpcs::configure_server(request.into_inner(), user, &conn),
        }
    }

    async fn update_post(&self, _request: Request<Post>) -> Result<Response<Post>, Status> {
        //TODO implement me!
        Ok(Response::new(Post {
            ..Default::default()
        }))
    }
    async fn delete_post(&self, _request: Request<Post>) -> Result<Response<Post>, Status> {
        //TODO implement me!
        Ok(Response::new(Post {
            ..Default::default()
        }))
    }
}

fn get_connection(pool: &PgPool) -> Result<PgPooledConnection, Status> {
    match pool.get() {
        Err(_) => Err(Status::new(Code::DataLoss, "database_connection_failure")),
        Ok(conn) => Ok(conn),
    }
}
