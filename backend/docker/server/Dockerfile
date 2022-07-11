FROM debian:10

RUN apt-get update && apt-get -y install libpq5

COPY backend/target/release/jonline__server_release /opt/jonline
COPY backend/target/release/expired_token_cleanup__server_release /opt/jonline-expired-token-cleanup

EXPOSE 50051

ENTRYPOINT /opt/jonline
