FROM alpine:3.8

SHELL ["sh", "-euxvc"]

ONBUILD ARG DOCKER_VERSION=19.03.4

ONBUILD RUN apk add --no-cache --virtual .deps ca-certificates curl; \
            curl -fsLo /tmp/docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"; \
            cd /tmp; \
            tar zxvf docker.tgz; \
            mv docker/* /usr/local/bin/; \
            # If the first two numbers are greater than or equal to 19, get rootless stuff too
            if [ "${DOCKER_VERSION:0:2}" -ge 19 ]; then \
              curl -fsLo /tmp/docker-rootless.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz"; \
              tar zxvf docker-rootless.tgz; \
              mv docker-rootless-extras/* /usr/local/bin/; \
            fi; \
            rm -rf /tmp/*; \
            apk del --no-cache .deps

