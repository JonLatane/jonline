mod jonline;
use jonline::jonline_server::{JonlineServer};

const FILE_DESCRIPTOR_SET: &[u8] =
    tonic::include_file_descriptor_set!("greeter_descriptor");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let addr = "[::1]:50051".parse().unwrap();
    let jonline = jonline::JonLineImpl::default();

    // Add this
    let reflection_service = tonic_reflection::server::Builder::configure()
        .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
        .build()
        .unwrap();

    println!("Jonline server listening on {}", addr);

    tonic::transport::Server::builder()
        .add_service(JonlineServer::new(jonline))
        .add_service(reflection_service) // Add this
        .serve(addr)
        .await?;

    Ok(())
}
