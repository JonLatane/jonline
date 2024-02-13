FROM --platform=linux/amd64 debian:stable-slim

RUN apt-get update && apt-get -y install libpq5 curl postgresql-client

# Old Ubuntu OpenSSL thing
# RUN curl http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.20_amd64.deb > libssl1.1.deb
# RUN dpkg -i libssl1.1.deb

# grpcurl is useful to have on a jonline instance!
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.9/grpcurl_1.8.9_linux_x86_64.tar.gz" | tar -xz -C /opt

# This hash is used by the GetServiceVersion RPC.
COPY deploys/docker/continuous_delivery_hash /opt/continuous_delivery_hash

# Jonline server binary (runs Rocket/FE/Web and Tonic/BE/gRPC services, all in one)
COPY backend/target/release/jonline__server_release /opt/jonline

# Background job binaries
COPY backend/target/release/disable_cdn_grpc__server_release /opt/disable_cdn_grpc
COPY backend/target/release/delete_expired_tokens__server_release /opt/delete_expired_tokens
COPY backend/target/release/delete_unowned_media__server_release /opt/delete_unowned_media

# Admin utility binaries
COPY backend/target/release/delete_preview_images__server_release /opt/delete_preview_images
COPY backend/target/release/set_permission__server_release /opt/set_permission
COPY backend/target/release/to_db_id__server_release /opt/to_db_id
COPY backend/target/release/to_proto_id__server_release /opt/to_proto_id

# Browser preview generator job binary. NOTE: USELESS (crashes) without a Chrome instance running against
# port 9222. See the Dockerfile in backend/docker/preview_generator for setup steps for Brave.
COPY backend/target/release/generate_preview_images__server_release /opt/generate_preview_images

# Flutter web app release (served from the filesystem by Rocket within Jonline)
COPY frontends/flutter/build/web/ /opt/flutter_web

# Tamagui web app release (served from the filesystem by Rocket within Jonline)
COPY frontends/tamagui/apps/next/out/ /opt/tamagui_web

# Generated protocol docs
COPY docs/protocol.html /opt/docs/protocol.html

EXPOSE 27707 8000 80 443 8001-9000

ENTRYPOINT ["/opt/jonline"]
