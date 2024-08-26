FROM --platform=linux/amd64 debian:stable-slim

RUN apt-get update && apt-get -y install libpq5
#curl postgresql-client

# Old Ubuntu OpenSSL thing
# RUN curl http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.20_amd64.deb > libssl1.1.deb
# RUN dpkg -i libssl1.1.deb

# grpcurl is useful to have on a jonline instance!
# RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.9/grpcurl_1.8.9_linux_x86_64.tar.gz" | tar -xz -C /opt

# This hash is used by the GetServiceVersion RPC.
COPY deploys/docker/continuous_delivery_hash /opt/continuous_delivery_hash

# Jonline LB binary
COPY backend/target/release/load_balancer__server_release /opt/load_balancer

EXPOSE 27707 8000 80 443 8001-9000 27709

# Start Jonline LB on port 27709.
ENTRYPOINT ["/opt/load_balancer", "::0:27709"]