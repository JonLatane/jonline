use std::time;
use jonline_server::Jonline;
use tonic::{Request, Response, Status};
include!("../target/compiled_protos/jonline.rs");

const VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Default)]
pub struct JonLineImpl {}

#[tonic::async_trait]
impl Jonline for JonLineImpl {
    async fn get_service_version(
        &self,
        _request: Request<()>,
    ) -> Result<Response<GetServiceVersionResponse>, Status> {
        let response = GetServiceVersionResponse {
            version: VERSION.to_owned()
        };
        Ok(Response::new(response))
    }

    async fn get_post(
        &self,
        request: Request<GetPostRequest>,
    ) -> Result<Response<Post>, Status> {
        println!("Request from {:?}", request.remote_addr());
        let now_as_secs = time::SystemTime::now()
            .duration_since(time::UNIX_EPOCH)
            .expect("Time went backwards")
            .as_secs() as i64;
    
        let response = Post {
            id: request.into_inner().id,
            author: Some(post::Author {
                user_id: "generated-user-id".to_owned(),
                username: "Peter".to_owned()
            }),
            created_at: Some(prost_types::Timestamp {
                seconds: now_as_secs,
                nanos: 0,
            }),
            updated_at: Some(prost_types::Timestamp {
                seconds: now_as_secs,
                nanos: 0,
            }),
            title: "Zero to One".to_owned(),
            content: "Hello hello hello".to_owned(),
            links: [].to_vec()
        };
        Ok(Response::new(response))
    }
}
