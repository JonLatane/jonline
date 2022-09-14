FROM debian:10

RUN apt-get update && apt-get -y install libpq5 curl

# grpcurl is useful to have on a jonline instance!
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz" | tar -xz -C /opt

COPY frontend/build/web/ /opt/web
COPY backend/target/release/jonline__server_release /opt/jonline
COPY backend/target/release/expired_token_cleanup__server_release /opt/jonline-expired-token-cleanup

EXPOSE 27707 8000 80 443

ENTRYPOINT /opt/jonline
