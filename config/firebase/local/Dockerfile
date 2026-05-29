FROM node:22-trixie-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends openjdk-21-jre-headless \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g firebase-tools@15.18.0

WORKDIR /workspace
