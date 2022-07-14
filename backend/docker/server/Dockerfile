FROM debian:10

RUN apt-get update && apt-get -y install libpq5

# The gRPC CLI is useful to have on a jonline instance, for debugging
# between services and stuff!
COPY backend/docker/server/grpc_cli /opt/grpc_cli
COPY backend/target/release/jonline__server_release /opt/jonline
COPY backend/target/release/expired_token_cleanup__server_release /opt/jonline-expired-token-cleanup

EXPOSE 27707

ENTRYPOINT /opt/jonline
