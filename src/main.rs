mod bookstore;
use bookstore::bookstore_server::{BookstoreServer};

const FILE_DESCRIPTOR_SET: &[u8] =
    tonic::include_file_descriptor_set!("greeter_descriptor");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "[::1]:50051".parse().unwrap();
    let bookstore = bookstore::BookStoreImpl::default();

    // Add this
    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()
        .unwrap();

    println!("Bookstore server listening on {}", addr);

    tonic::transport::Server::builder()
        .add_service(BookstoreServer::new(bookstore))
        .add_service(reflection_service) // Add this
        .serve(addr)
        .await?;

    Ok(())
}
