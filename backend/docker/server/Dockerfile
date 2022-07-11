FROM debian:10

RUN apt-get update && apt-get -y install libpq5

COPY backend/target/release/jonline-server-release /opt/jonline

EXPOSE 50051

ENTRYPOINT /opt/jonline
