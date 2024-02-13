FROM --platform=linux/amd64 debian:stable-slim

# The preview generator image only includes the background job binary and a tool to delete images. Other Jonline binaries aren't really useful;
# the bulk of this image will be the Chrome distro included.
#
# Note that its entrypoint is a headless browser, which is necessary for the preview generator to work. A cluster job of some sort must
# run /opt/generate_preview_images periodically (which is set up automatically in Jonline deployment as a K8s CronJob).
COPY backend/target/release/generate_preview_images__server_release /opt/generate_preview_images
COPY backend/target/release/delete_preview_images__server_release /opt/delete_preview_images

# Setup the environment for the preview generator.
RUN apt-get update && apt-get -y install libpq5 curl postgresql-client

# Old Ubuntu OpenSSL thing
# RUN curl http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.20_amd64.deb > libssl1.1.deb
# RUN dpkg -i libssl1.1.deb

# grpcurl is useful to have on a jonline instance!
RUN curl -sSL "https://github.com/fullstorydev/grpcurl/releases/download/v1.8.9/grpcurl_1.8.9_linux_x86_64.tar.gz" | tar -xz -C /opt

# Install Chrome-related dependencies
RUN apt-get -y install gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 \
libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 \
libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils wget gpg fonts-noto-color-emoji

# Copy emoji-supporting fonts
RUN mkdir -p /usr/local/share/fonts/truetype
RUN cp -r /usr/share/fonts/truetype/noto /usr/local/share/fonts/truetype/noto

# Install Brave browser and xvfb
RUN apt-get -y install apt-transport-https curl gnupg xvfb
# RUN curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
# RUN echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
RUN curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list
RUN apt update
RUN apt-get -y install brave-browser

# Install Chrome Beta (for --headless=chrome flag support, needed for extensions)
# RUN wget -qO - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg
# RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
# RUN apt update
# RUN apt-get -y install google-chrome-beta

# Chrome ad/cookie blockers for screenshot generator
# COPY backend/docker/preview_generator/preview_generator_extensions /opt/preview_generator_extensions

EXPOSE 27707 8000 80 443 8001-9000 9222

ENTRYPOINT xvfb-run brave-browser --remote-debugging-port=9222 --disable-gpu --no-sandbox https://www.google.com
