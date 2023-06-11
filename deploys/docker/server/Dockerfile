FROM debian:stable-slim

RUN apt-get update && apt-get -y install libpq5 curl postgresql-client

# grpcurl is useful to have on a jonline instance!
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz" | tar -xz -C /opt

# Jonline server binary (runs Rocket/FE/Web and Tonic/BE/gRPC services, all in one)
COPY backend/target/release/jonline__server_release /opt/jonline

# Background job binaries
COPY backend/target/release/delete_expired_tokens__server_release /opt/delete_expired_tokens
COPY backend/target/release/delete_unowned_media__server_release /opt/delete_unowned_media

# Admin utility binaries
COPY backend/target/release/delete_preview_images__server_release /opt/delete_preview_images
COPY backend/target/release/set_permission__server_release /opt/set_permission

# Browser preview generator job binary. NOTE: USELESS (crashes) without a Chrome instance running against
# port 9222. See the Dockerfile in backend/docker/preview_generator for setup steps for Brave.
COPY backend/target/release/generate_preview_images__server_release /opt/generate_preview_images

# Flutter web app release (served from the filesystem by Rocket within Jonline)
COPY frontends/flutter/build/web/ /opt/flutter_web

# Tamagui web app release (served from the filesystem by Rocket within Jonline)
COPY frontends/tamagui/apps/next/out/ /opt/tamagui_web

EXPOSE 27707 8000 80 443 8001-9000

ENTRYPOINT ["/opt/jonline"]
