FROM --platform=linux/amd64 rust:1.70.0

# Install depends for grpcio.
RUN cargo install protobuf-codegen
RUN cargo install grpcio-compiler
RUN apt-get update && apt-get -y install protobuf-compiler

# golang and cmake use to build server.
RUN apt-get -y install golang cmake

WORKDIR /opt
