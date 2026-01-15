#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM node:20-bookworm AS builder
LABEL maintainer="Johannes Kepper"

ARG GITHUB_REF_NAME=main
ENV API_BUILD_HOME="/opt/api-build"
ENV GITHUB_REF_NAME=${GITHUB_REF_NAME}
ENV DOCKER_BUILD=true

WORKDIR ${API_BUILD_HOME}

RUN apt-get update \
    && apt-get install -y git

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run dist:full


#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb:6.4.0-jre17

LABEL org.opencontainers.image.title="Beethovens Werkstatt API"
LABEL org.opencontainers.image.description="API for MEI-encoded music data and genetic editions"
LABEL org.opencontainers.image.source="https://github.com/BeethovensWerkstatt/api"
LABEL org.opencontainers.image.vendor="Beethovens Werkstatt"

# API specific settings
# For more details: https://github.com/peterstadler/existdb-docker
ENV EXIST_ENV="production"
ENV EXIST_CONTEXT_PATH="/"
ENV EXIST_DEFAULT_APP_PATH="xmldb:exist:///db/apps/api"

# Environment for configuration
ENV BW_ENV="production"

# Admin password MUST be set via environment variable at runtime:
# docker run -e EXIST_PASSWORD="secure-password" ...
# Or use Docker secrets for orchestration platforms.

WORKDIR /opt/exist

# Copy custom entrypoint and API package
USER root
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY --from=builder /opt/api-build/dist/api-*.xar ${EXIST_HOME}/autodeploy/
RUN chown wegajetty:wegajetty ${EXIST_HOME}/autodeploy/api-*.xar \
    && ls -lh ${EXIST_HOME}/autodeploy/api-*.xar

USER wegajetty

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=60s \
    CMD curl -f http://localhost:8080/api/health || exit 1

# Expose ports
EXPOSE 8080 8443

# Override entrypoint to use our custom startup script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
