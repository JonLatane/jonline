use tonic::{transport::Server, Request, Response, Status};

use bookstore::bookstore_server::{Bookstore, BookstoreServer};
use bookstore::{GetBookRequest, GetBookResponse};


mod bookstore {
    include!("bookstore.rs");
}


#[derive(Default)]
pub struct BookStoreImpl {}

#[tonic::async_trait]
impl Bookstore for BookStoreImpl {
    async fn get_book(
        &self,
        request: Request<GetBookRequest>,
    ) -> Result<Response<GetBookResponse>, Status> {
        println!("Request from {:?}", request.remote_addr());

        let response = GetBookResponse {
            id: request.into_inner().id,
            author: "Peter".to_owned(),
            name: "Zero to One".to_owned(),
            year: 2014,
        };
        Ok(Response::new(response))
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "[::1]:50051".parse().unwrap();
    let bookstore = BookStoreImpl::default();

    println!("Bookstore server listening on {}", addr);

    Server::builder()
        .add_service(BookstoreServer::new(bookstore))
        .serve(addr)
        .await?;

    Ok(())
}
