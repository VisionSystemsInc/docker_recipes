FROM alpine:3.8

SHELL ["sh", "-euxvc"]

ONBUILD ARG DOCKER_COMPOSE_VERSION=1.24.1

ONBUILD RUN apk add --no-cache --virtual .deps ca-certificates curl; \
            curl -fsLo /usr/local/bin/docker-compose https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`;\
            chmod +x /usr/local/bin/docker-compose; \
            apk del --no-cache .deps

