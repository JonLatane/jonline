FROM debian:10

RUN apt-get update && apt-get -y install libpq5

COPY target/release/jonline_tonic /opt/jonline_tonic

EXPOSE 50051

ENTRYPOINT /opt/jonline_tonic
