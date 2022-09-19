FROM debian:11.5

RUN apt-get update && apt-get -y install libpq5 curl 

# grpcurl is useful to have on a jonline instance!
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz" | tar -xz -C /opt

# Flutter web app release (served from the filesystem by Rocket within Jonline)
COPY frontend/build/web/ /opt/web

# Jonline server binary (runs Rocket/FE/Web and Tonic/BE/gRPC services, all in one)
COPY backend/target/release/jonline__server_release /opt/jonline

# Background job binary
COPY backend/target/release/delete_expired_tokens__server_release /opt/delete_expired_tokens
COPY backend/target/release/generate_preview_images__server_release /opt/generate_preview_images
COPY backend/target/release/delete_preview_images__server_release /opt/delete_preview_images

# Ad/cookie blockers for screenshot generator
COPY backend/docker/server/ublock /opt/ublock/
COPY backend/docker/server/nocookies /opt/nocookies/

EXPOSE 27707 8000 80 443 8001-9000

ENTRYPOINT /opt/jonline
