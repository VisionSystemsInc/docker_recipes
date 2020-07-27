# ARG DOCKER_COMPOSE_VERSION=1.26.2
# FROM docker/compose:alpine-${DOCKER_COMPOSE_VERSION} as docker-compose_musl
# FROM docker/compose:debian-${DOCKER_COMPOSE_VERSION} as docker-compose_glib

FROM alpine:3.11
ADD docker-compose /usr/local/bin/docker-compose
RUN chmod 755 /usr/local/bin/docker-compose

# COPY --from=docker-compose_musl /usr/local/bin/docker-compose /usr/local/bin/docker-compose_musl
# COPY --from=docker-compose_glib /usr/local/bin/docker-compose /usr/local/bin/docker-compose_glib
