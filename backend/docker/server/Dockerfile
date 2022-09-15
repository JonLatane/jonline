FROM debian:11.5

RUN apt-get update && apt-get -y install libpq5 curl 

# Install headless Chrome and stuff needed for it
RUN apt-get -y install chromium gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget

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

EXPOSE 27707 8000 80 443 8001-9000

ENTRYPOINT /opt/jonline
