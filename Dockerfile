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

# non-root user version
# # Create a user for running flutter.
# RUN groupadd -r -g 1337 flutter
# RUN useradd  -r -u 1337 -g flutter -m flutter
# USER flutter:flutter

# root user version
RUN mkdir -p /home/flutter

# Install flutter.
ARG FLUTTER_VERSION="3.16.4"

WORKDIR /home/flutter
# non-root user version
# ADD --chown=flutter:flutter https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz flutter_linux.tar.xz
# root user version
ADD https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz flutter_linux.tar.xz
RUN tar xf flutter_linux.tar.xz
RUN rm flutter_linux.tar.xz
RUN ls -la

# Setup paths for flutter installation.
ENV FLUTTER_HOME="/home/flutter/flutter"
ENV PATH="$PATH:${FLUTTER_HOME}/bin"
ENV PATH="$PATH:${FLUTTER_HOME}/bin/cache/dart-sdk/bin"
ENV PATH="$PATH:${HOME}/.pub-cache/bin"

# Download the version of chrome-driver matching the installed chrome version.
# For details how this works, see:
# https://chromedriver.chromium.org/downloads/version-selection
RUN CHROME_VERSION=$(google-chrome --product-version) && \
    wget -q --continue -P /home/flutter/ https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/${CHROME_VERSION}/linux64/chromedriver-linux64.zip && \
    unzip chromedriver-linux64.zip && \
    mv chromedriver-linux64 chromedriver && \
    rm chromedriver-linux64.zip

# Put Chromedriver into the PATH
ENV PATH $PATH:/home/flutter/chromedriver

# Preconfigure flutter.
RUN flutter precache
RUN flutter config --no-analytics

# Dump status of flutter installation.
RUN flutter doctor