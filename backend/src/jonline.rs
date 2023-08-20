use crate::models;
use crate::protos::*;
use jonline_server::Jonline;
use std::sync::Arc;
use tonic::{Code, Request, Response, Status};

use crate::auth;
use crate::db_connection::*;
use crate::rpcs;

use futures::Stream;
use std::{pin::Pin, time::Duration};
use tokio::sync::mpsc;
use tokio_stream::{wrappers::ReceiverStream, StreamExt};

pub struct JonLineImpl {
    pub pool: Arc<PgPool>,
    pub bucket: Arc<s3::Bucket>,
}

impl Clone for JonLineImpl {
    fn clone(&self) -> Self {
        JonLineImpl {
            pool: self.pool.clone(),
            bucket: self.bucket.clone(),
        }
    }
}

type ReplyStreamResult<T> = Result<Response<T>, Status>;
type ReplyStream = Pin<Box<dyn Stream<Item = Result<Post, Status>> + Send>>;

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
    ) -> Result<Response<RefreshTokenResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::create_account(request.into_inner(), &mut conn).map(Response::new)
    }

    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<RefreshTokenResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::login(request, &mut conn)
    }

    async fn access_token(
        &self,
        request: Request<AccessTokenRequest>,
    ) -> Result<Response<AccessTokenResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        rpcs::access_token(request, &mut conn)
    }

    async fn get_current_user(&self, request: Request<()>) -> Result<Response<User>, Status> {
        let mut conn = get_connection(&self.pool)?;
        match auth::get_auth_user(&request, &mut conn) {
            Err(e) => Err(e),
            Ok(user) => rpcs::get_current_user(user, &mut conn),
        }
    }

    async fn update_user(&self, request: Request<User>) -> Result<Response<User>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_user(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn delete_user(&self, request: Request<User>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_user(request.into_inner(), user, &mut conn).map(Response::new)
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

    async fn get_media(
        &self,
        request: Request<GetMediaRequest>,
    ) -> Result<Response<GetMediaResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_media(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn delete_media(&self, request: Request<Media>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_media(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn get_groups(
        &self,
        request: Request<GetGroupsRequest>,
    ) -> Result<Response<GetGroupsResponse>, Status> {
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

    async fn create_membership(
        &self,
        request: Request<Membership>,
    ) -> Result<Response<Membership>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_membership(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn update_membership(
        &self,
        request: Request<Membership>,
    ) -> Result<Response<Membership>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_membership(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn delete_membership(
        &self,
        request: Request<Membership>,
    ) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_membership(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn get_members(
        &self,
        request: Request<GetMembersRequest>,
    ) -> Result<Response<GetMembersResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::get_members(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn create_post(
        &self,
        request: Request<Post>,
    ) -> Result<Response<Post>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_post(request, user, &mut conn)
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

    async fn create_group_post(
        &self,
        request: Request<GroupPost>,
    ) -> Result<Response<GroupPost>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_group_post(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn update_group_post(
        &self,
        request: Request<GroupPost>,
    ) -> Result<Response<GroupPost>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::update_group_post(request.into_inner(), user, &mut conn).map(Response::new)
    }
    async fn delete_group_post(&self, request: Request<GroupPost>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::delete_group_post(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn get_group_posts(
        &self,
        request: Request<GetGroupPostsRequest>,
    ) -> Result<Response<GetGroupPostsResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_group_posts(request.into_inner(), user, &mut conn).map(Response::new)
    }

    async fn get_posts(
        &self,
        request: Request<GetPostsRequest>,
    ) -> Result<Response<GetPostsResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_posts(request.into_inner(), user, &mut conn).map(Response::new)
    }

    type StreamRepliesStream = ReplyStream;
    async fn stream_replies(
        &self,
        req: Request<Post>,
    ) -> ReplyStreamResult<Self::StreamRepliesStream> {
        println!("Jonline::stream_replies");
        println!("\tclient connected from: {:?}", req.remote_addr());

        // creating infinite stream with requested message
        let repeat = std::iter::repeat(Post {
            content: Some("Hello World!".to_string()),
            ..Default::default()
        });
        let mut stream = Box::pin(tokio_stream::iter(repeat).throttle(Duration::from_millis(200)));

        // spawn and channel are required if you want handle "disconnect" functionality
        // the `out_stream` will not be polled after client disconnect
        let (tx, rx) = mpsc::channel(128);
        tokio::spawn(async move {
            while let Some(item) = stream.next().await {
                match tx.send(Result::<_, Status>::Ok(item)).await {
                    Ok(_) => {
                        // item (server response) was queued to be send to client
                    }
                    Err(_item) => {
                        // output_stream was build from rx and both are dropped
                        break;
                    }
                }
            }
            println!("\tclient disconnected");
        });

        let output_stream = ReceiverStream::new(rx);
        Ok(Response::new(
            Box::pin(output_stream) as Self::StreamRepliesStream
        ))
    }

    async fn create_event(&self, request: Request<Event>) -> Result<Response<Event>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::create_event(request, user, &mut conn)
    }

    async fn get_events(
        &self,
        request: Request<GetEventsRequest>,
    ) -> Result<Response<GetEventsResponse>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&request, &mut conn).ok();
        rpcs::get_events(request.into_inner(), user, &mut conn).map(Response::new)
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
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::configure_server(request.into_inner(), user, &mut conn)
    }

    async fn reset_data(&self, request: Request<()>) -> Result<Response<()>, Status> {
        let mut conn = get_connection(&self.pool)?;
        let user = auth::get_auth_user(&request, &mut conn)?;
        rpcs::reset_data(user, &mut conn).map(Response::new)
    }
}

fn get_connection(pool: &PgPool) -> Result<PgPooledConnection, Status> {
    match pool.get() {
        Err(_) => Err(Status::new(Code::DataLoss, "database_connection_failure")),
        Ok(conn) => Ok(conn),
    }
}
