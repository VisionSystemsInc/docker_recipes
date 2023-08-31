FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG DOCKER_COMPOSE_VERSION=2.1.1

ONBUILD RUN apk add --no-cache --virtual .deps curl ca-certificates; \
            curl -fsSLO https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64; \
            curl -fsSLO https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64.sha256; \
            sha256sum -c docker-compose-linux-x86_64.sha256; \
            rm docker-compose-linux-x86_64.sha256; \
            mkdir -p /usr/local/libexec/docker/cli-plugins; \
            mv docker-compose-linux-x86_64 /usr/local/libexec/docker/cli-plugins/docker-compose; \
            ls -la /usr/local/bin; \
            ln -s /usr/local/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose; \
            chmod +x /usr/local/bin/docker-compose; \
            apk del .deps
