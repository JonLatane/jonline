FROM debian:11.5

RUN apt-get update && apt-get -y install libpq5 curl postgresql-client

# grpcurl is useful to have on a jonline instance!
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz" | tar -xz -C /opt

# Flutter web app release (served from the filesystem by Rocket within Jonline)
COPY frontends/flutter/build/web/ /opt/flutter_web

# Tamagui web app release (served from the filesystem by Rocket within Jonline)
COPY frontends/tamagui/apps/next/out/ /opt/tamagui_web

# Copy the Jonline web templates.
# COPY web/ /opt/web
COPY web/ /templates

# Jonline server binary (runs Rocket/FE/Web and Tonic/BE/gRPC services, all in one)
COPY backend/target/release/jonline__server_release /opt/jonline

# Background job binaries
COPY backend/target/release/delete_expired_tokens__server_release /opt/delete_expired_tokens

# Admin utility binaries
COPY backend/target/release/delete_preview_images__server_release /opt/delete_preview_images
COPY backend/target/release/set_permission__server_release /opt/set_permission

# Cache warmup for server
COPY backend/docker/server/jonline_with_warmup.sh /opt/jonline_with_warmup.sh

# No need for the preview generator though!
# COPY backend/target/release/generate_preview_images__server_release /opt/generate_preview_images

EXPOSE 27707 8000 80 443 8001-9000

ENTRYPOINT /opt/jonline_with_warmup.sh
