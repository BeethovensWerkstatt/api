#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM node:18-bookworm AS builder
LABEL maintainer="Johannes Kepper"

ENV API_BUILD_HOME="/opt/api-build"

WORKDIR ${API_BUILD_HOME}

RUN apt-get update \
    && apt-get install -y git

COPY . .

RUN npm install \
    && npm run dist:full


#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb:6.4.0-jre17

# add API specific settings
# For more details about the options see
# https://github.com/peterstadler/existdb-docker
# Using development mode to allow RESTXQ module registration
# TODO: For production, need to configure permissions properly
ENV EXIST_ENV="restxq"
ENV EXIST_CONTEXT_PATH="/"
# ENV EXIST_DEFAULT_APP_PATH="xmldb:exist:///db/apps/api"

# Admin password MUST be set via environment variable at runtime:
# docker run -e EXIST_PASSWORD="secure-password" ...
# Or use Docker secrets for orchestration platforms.
# If not set, will fall back to base image default.

WORKDIR /opt/exist

# Copy custom entrypoint and API package
USER root
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY --from=builder /opt/api-build/dist/api-*.xar ${EXIST_HOME}/autodeploy/
RUN chown wegajetty:wegajetty ${EXIST_HOME}/autodeploy/api-*.xar \
    && ls -lh ${EXIST_HOME}/autodeploy/api-*.xar

USER wegajetty

# Override entrypoint to use our custom startup script
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
