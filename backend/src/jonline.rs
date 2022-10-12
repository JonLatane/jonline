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
        rpcs::get_service_version().map(Response::new)
    }

    async fn create_account(
        &self,
        request: Request<CreateAccountRequest>,
    ) -> Result<Response<AuthTokenResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::create_account(request.into_inner(), &mut conn).map(Response::new)
    }

    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<AuthTokenResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::login(request, &mut conn)
    }

    async fn refresh_token(
        &self,
        request: Request<RefreshTokenRequest>,
    ) -> Result<Response<ExpirableToken>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::refresh_token(request, &mut conn)
    }

    async fn get_current_user(&self, request: Request<()>) -> Result<Response<User>, Status> {
        let mut conn = get_connection(&self.pool)?;
        match auth::get_auth_user(&request, &mut conn) {
            Err(e) => Err(e),
            Ok(user) => rpcs::get_current_user(user),
        }
    }

    async fn update_user(&self, request: Request<User>) -> Result<Response<User>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_user(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn create_post(
        &self,
        request: Request<CreatePostRequest>,
    ) -> Result<Response<Post>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_post(request, user, &mut conn)
        // match auth::get_auth_user(&request, &mut conn) {
        //     Err(e) => Err(e),
        //     Ok(user) => rpcs::create_post(request, user, &mut conn),
        // }
    }

    async fn get_posts(
        &self,
        request: Request<GetPostsRequest>,
    ) -> Result<Response<Posts>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_posts(request, user, &mut conn)
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
        let mut conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_users(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn create_follow(&self, request: Request<Follow>) -> Result<Response<Follow>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_follow(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn update_follow(&self, request: Request<Follow>) -> Result<Response<Follow>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_follow(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn delete_follow(&self, request: Request<Follow>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_follow(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn get_groups(&self, request: Request<GetGroupsRequest>) -> Result<Response<GetGroupsResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_groups(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn create_group(&self, request: Request<Group>) -> Result<Response<Group>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_group(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn update_group(&self, request: Request<Group>) -> Result<Response<Group>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_group(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn delete_group(&self, request: Request<Group>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_group(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn create_membership(&self, request: Request<Membership>) -> Result<Response<Membership>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_membership(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn update_membership(&self, request: Request<Membership>) -> Result<Response<Membership>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_membership(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn delete_membership(&self, request: Request<Membership>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_membership(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn get_server_configuration(
        &self,
        _request: Request<()>,
    ) -> Result<Response<ServerConfiguration>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::get_server_configuration(&mut conn).map(Response::new)
    }

    async fn configure_server(
        &self,
        request: Request<ServerConfiguration>,
    ) -> Result<Response<ServerConfiguration>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn) ?;
        rpcs::configure_server(request.into_inner(), user, &mut conn)
    }

    async fn reset_data(
        &self,
        request: Request<()>,
    ) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn) ?;
        rpcs::reset_data(user, &mut conn).map(Response::new)
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
