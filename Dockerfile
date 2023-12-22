FROM ubuntu:22.04

LABEL org.opencontainers.image.source=https://github.com/tauu/docker-flutter-web-driver

# Install dependencies for flutter. For a list of all dependencies,
# see https://docs.flutter.dev/get-started/install/linux
RUN apt-get update && \
    apt-get install -y bash curl git unzip xz-utils zip wget gnupg2
    
# Install google chrome from official apt.
RUN curl https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list
RUN apt-get update -y  && \
    apt-get install -y xvfb google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Uninstall chrome again, it is only installed so that all dependencies of 
# chrome for testing are available.    
RUN apt-get remove -y google-chrome-stable

# non-root user version
# # Create a user for running flutter.
# RUN groupadd -r -g 1337 flutter
# RUN useradd  -r -u 1337 -g flutter -m flutter
# USER flutter:flutter

# root user version
RUN mkdir -p /home/flutter

WORKDIR /home/flutter

# Download the latest stable version of chrome and chromedriver.
# For details how this works, see:
# https://chromedriver.chromium.org/downloads/version-selection
RUN LATEST_CHROME_STABLE=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json | jq '.channels.Stable') && \
    LATEST_CHROME_STABLE_URL=$(echo "$LATEST_CHROME_STABLE" | jq -r '.downloads.chrome[] | select(.platform == "linux64") | .url') && \
    curl -JO "$LATEST_CHROME_STABLE_URL" && \
    unzip chrome-linux64.zip && \
    rm chrome-linux64.zip && \
    mv chrome-linux64 chrome

RUN LATEST_CHROME_STABLE=$(curl -s https://googlechromelabs.github.io/chrome-for-testing/last-known-good-versions-with-downloads.json | jq '.channels.Stable') && \
    LATEST_CHROMEDRIVER_STABLE_URL=$(echo "$LATEST_CHROME_STABLE" | jq -r '.downloads.chromedriver[] | select(.platform == "linux64") | .url') && \
    curl -JO "$LATEST_CHROMEDRIVER_STABLE_URL" && \
    unzip chromedriver-linux64.zip && \
    rm chromedriver-linux64.zip && \
    mv chromedriver-linux64 chromedriver

# Put chrome and chromedriver into the PATH.
ENV PATH $PATH:/home/flutter/chrome
ENV PATH $PATH:/home/flutter/chromedriver

# Install flutter.
ARG FLUTTER_VERSION="3.13.9"

ADD https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz flutter_linux.tar.xz
RUN tar xf flutter_linux.tar.xz
RUN rm flutter_linux.tar.xz
# root user version
RUN chown -R root:root flutter
# non-root user version
# RUN chown -R flutter:flutter flutter

# Setup paths for flutter installation.
ENV FLUTTER_HOME="/home/flutter/flutter"
ENV PATH="$PATH:${FLUTTER_HOME}/bin"
ENV PATH="$PATH:${FLUTTER_HOME}/bin/cache/dart-sdk/bin"
ENV PATH="$PATH:${HOME}/.pub-cache/bin"

# Preconfigure flutter.
RUN flutter precache
RUN flutter config --no-analytics

# Dump status of flutter installation.
RUN flutter doctor

# Create folder to store the source of a flutterproject and set it as workdir.
RUN mkdir src
WORKDIR /home/flutter/src