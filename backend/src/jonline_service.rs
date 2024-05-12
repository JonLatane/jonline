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

pub struct JonlineService {
    pub pool: Arc<PgPool>,
    pub bucket: Arc<s3::Bucket>,
}

impl Clone for JonlineService {
    fn clone(&self) -> Self {
        JonlineService {
            pool: self.pool.clone(),
            bucket: self.bucket.clone(),
        }
    }
}

type ReplyStreamResult<T> = Result<Response<T>, Status>;
type ReplyStream = Pin<Box<dyn Stream<Item = Result<Post, Status>> + Send>>;

macro_rules! auth_rpc {
    ($self: expr, $rpc:expr, $request:expr) => {{
        let mut conn = get_connection(&$self.pool)?;
        log::info!(
            "Auth RPC called: {} (request/result hidden)",
            stringify!($rpc)
        );
        $rpc($request.into_inner(), &mut conn).map(Response::new)
    }};
}

macro_rules! authenticated_rpc {
    ($self: expr, $rpc:expr, $request:expr) => {{
        let mut conn = get_connection(&$self.pool)?;
        let user = auth::get_auth_user(&$request, &mut conn)?.ok_or(Status::new(
            Code::Unauthenticated,
            "authentication_required",
        ))?;
        let inner = $request.into_inner();
        let request_log = format!("{:?}", &inner);
        let result = $rpc(inner, &user, &mut conn);
        let truncated_result = format!("{:?}", &result)
            .chars()
            .take(1000)
            .collect::<String>();
        log::info!(
            "Authenticated RPC: {}\tRequest: {:?}\tResult: {:?}",
            stringify!($rpc),
            request_log,
            truncated_result
        );
        result.map(Response::new)
    }};
}

macro_rules! unauthenticated_rpc {
    ($self: expr, $rpc:expr, $request:expr) => {{
        let mut conn = get_connection(&$self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&$request, &mut conn)?;
        let inner = $request.into_inner();
        let request_log = format!("{:?}", &inner);
        let result = $rpc(inner, &user.as_ref(), &mut conn);
        let truncated_result = format!("{:?}", &result)
            .chars()
            .take(1000)
            .collect::<String>();
        log::info!(
            "Unauthenticated RPC: {}\tRequest: {:?}\tResult: {:?}",
            stringify!($rpc),
            request_log,
            truncated_result
        );
        result.map(Response::new)
    }};
}

macro_rules! unauthenticated_unlogged_rpc {
    ($self: expr, $rpc:expr, $request:expr) => {{
        let mut conn = get_connection(&$self.pool)?;
        let user: Option<models::User> = auth::get_auth_user(&$request, &mut conn).ok().flatten();
        let inner = $request.into_inner();
        let result = $rpc(inner, &user.as_ref(), &mut conn);
        result.map(Response::new)
    }};
}

#[tonic::async_trait]
impl Jonline for JonlineService {
    async fn get_service_version(
        &self,
        _request: Request<()>,
    ) -> Result<Response<GetServiceVersionResponse>, Status> {
        rpcs::get_service_version().map(Response::new)
    }

    async fn get_server_configuration(
        &self,
        request: Request<()>,
    ) -> Result<Response<ServerConfiguration>, Status> {
        unauthenticated_rpc!(self, rpcs::get_server_configuration, request)
    }

    async fn configure_server(
        &self,
        request: Request<ServerConfiguration>,
    ) -> Result<Response<ServerConfiguration>, Status> {
        authenticated_rpc!(self, rpcs::configure_server, request)
    }

    async fn reset_data(&self, request: Request<()>) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::reset_data, request)
    }

    async fn create_account(
        &self,
        request: Request<CreateAccountRequest>,
    ) -> Result<Response<RefreshTokenResponse>, Status> {
        auth_rpc!(self, rpcs::create_account, request)
    }

    async fn login(
        &self,
        request: Request<LoginRequest>,
    ) -> Result<Response<RefreshTokenResponse>, Status> {
        auth_rpc!(self, rpcs::login, request)
    }

    async fn access_token(
        &self,
        request: Request<AccessTokenRequest>,
    ) -> Result<Response<AccessTokenResponse>, Status> {
        auth_rpc!(self, rpcs::access_token, request)
    }

    async fn reset_password(
        &self,
        request: Request<ResetPasswordRequest>,
    ) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::reset_password, request)
    }

    async fn get_current_user(&self, request: Request<()>) -> Result<Response<User>, Status> {
        authenticated_rpc!(self, rpcs::get_current_user, request)
    }

    async fn update_user(&self, request: Request<User>) -> Result<Response<User>, Status> {
        authenticated_rpc!(self, rpcs::update_user, request)
    }

    async fn delete_user(&self, request: Request<User>) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::delete_user, request)
    }
    async fn get_users(
        &self,
        request: Request<GetUsersRequest>,
    ) -> Result<Response<GetUsersResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_users, request)
    }

    async fn create_follow(&self, request: Request<Follow>) -> Result<Response<Follow>, Status> {
        authenticated_rpc!(self, rpcs::create_follow, request)
    }
    async fn update_follow(&self, request: Request<Follow>) -> Result<Response<Follow>, Status> {
        authenticated_rpc!(self, rpcs::update_follow, request)
    }
    async fn delete_follow(&self, request: Request<Follow>) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::delete_follow, request)
    }

    async fn get_media(
        &self,
        request: Request<GetMediaRequest>,
    ) -> Result<Response<GetMediaResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_media, request)
    }

    async fn delete_media(&self, request: Request<Media>) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::delete_media, request)
    }

    async fn get_groups(
        &self,
        request: Request<GetGroupsRequest>,
    ) -> Result<Response<GetGroupsResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_groups, request)
    }

    async fn create_group(&self, request: Request<Group>) -> Result<Response<Group>, Status> {
        authenticated_rpc!(self, rpcs::create_group, request)
    }

    async fn update_group(&self, request: Request<Group>) -> Result<Response<Group>, Status> {
        authenticated_rpc!(self, rpcs::update_group, request)
    }
    async fn delete_group(&self, request: Request<Group>) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::delete_group, request)
    }

    async fn create_membership(
        &self,
        request: Request<Membership>,
    ) -> Result<Response<Membership>, Status> {
        authenticated_rpc!(self, rpcs::create_membership, request)
    }
    async fn update_membership(
        &self,
        request: Request<Membership>,
    ) -> Result<Response<Membership>, Status> {
        authenticated_rpc!(self, rpcs::update_membership, request)
    }
    async fn delete_membership(
        &self,
        request: Request<Membership>,
    ) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::delete_membership, request)
    }
    async fn get_members(
        &self,
        request: Request<GetMembersRequest>,
    ) -> Result<Response<GetMembersResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_members, request)
    }

    async fn create_post(&self, request: Request<Post>) -> Result<Response<Post>, Status> {
        authenticated_rpc!(self, rpcs::create_post, request)
    }
    async fn update_post(&self, request: Request<Post>) -> Result<Response<Post>, Status> {
        authenticated_rpc!(self, rpcs::update_post, request)
    }
    async fn delete_post(&self, request: Request<Post>) -> Result<Response<Post>, Status> {
        authenticated_rpc!(self, rpcs::delete_post, request)
    }

    async fn star_post(&self, request: Request<Post>) -> Result<Response<Post>, Status> {
        unauthenticated_unlogged_rpc!(self, rpcs::star_post, request)
    }

    async fn unstar_post(&self, request: Request<Post>) -> Result<Response<Post>, Status> {
        unauthenticated_unlogged_rpc!(self, rpcs::unstar_post, request)
    }

    async fn create_group_post(
        &self,
        request: Request<GroupPost>,
    ) -> Result<Response<GroupPost>, Status> {
        authenticated_rpc!(self, rpcs::create_group_post, request)
    }
    async fn update_group_post(
        &self,
        request: Request<GroupPost>,
    ) -> Result<Response<GroupPost>, Status> {
        authenticated_rpc!(self, rpcs::update_group_post, request)
    }
    async fn delete_group_post(&self, request: Request<GroupPost>) -> Result<Response<()>, Status> {
        authenticated_rpc!(self, rpcs::delete_group_post, request)
    }

    async fn get_group_posts(
        &self,
        request: Request<GetGroupPostsRequest>,
    ) -> Result<Response<GetGroupPostsResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_group_posts, request)
    }

    async fn get_posts(
        &self,
        request: Request<GetPostsRequest>,
    ) -> Result<Response<GetPostsResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_posts, request)
    }

    async fn create_event(&self, request: Request<Event>) -> Result<Response<Event>, Status> {
        authenticated_rpc!(self, rpcs::create_event, request)
    }
    async fn update_event(&self, request: Request<Event>) -> Result<Response<Event>, Status> {
        authenticated_rpc!(self, rpcs::update_event, request)
    }
    async fn delete_event(&self, request: Request<Event>) -> Result<Response<Event>, Status> {
        authenticated_rpc!(self, rpcs::delete_event, request)
    }
    async fn get_events(
        &self,
        request: Request<GetEventsRequest>,
    ) -> Result<Response<GetEventsResponse>, Status> {
        unauthenticated_rpc!(self, rpcs::get_events, request)
    }

    async fn upsert_event_attendance(
        &self,
        request: Request<EventAttendance>,
    ) -> Result<Response<EventAttendance>, Status> {
        unauthenticated_rpc!(self, rpcs::upsert_event_attendance, request)
    }
    async fn delete_event_attendance(
        &self,
        request: Request<EventAttendance>,
    ) -> Result<Response<()>, Status> {
        unauthenticated_rpc!(self, rpcs::delete_event_attendance, request)
    }
    async fn get_event_attendances(
        &self,
        request: Request<GetEventAttendancesRequest>,
    ) -> Result<Response<EventAttendances>, Status> {
        unauthenticated_rpc!(self, rpcs::get_event_attendances, request)
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
}

fn get_connection(pool: &PgPool) -> Result<PgPooledConnection, Status> {
    match pool.get() {
        Err(_) => Err(Status::new(Code::DataLoss, "database_connection_failure")),
        Ok(conn) => Ok(conn),
    }
}
