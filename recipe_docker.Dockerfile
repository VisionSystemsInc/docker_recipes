FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG DOCKER_VERSION=19.03.5

ONBUILD RUN apk add --no-cache --virtual .deps ca-certificates curl; \
            curl -fsSLo /tmp/docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz"; \
            cd /tmp; \
            tar zxf docker.tgz; \
            mv docker/* /usr/local/bin/; \
            # If the first two numbers are greater than or equal to 19, get rootless stuff too
            if [ "${DOCKER_VERSION:0:2}" -ge "19" ]; then \
              curl -fsSLo /tmp/docker-rootless.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-rootless-extras-${DOCKER_VERSION}.tgz"; \
              tar zxf docker-rootless.tgz; \
              mv docker-rootless-extras/* /usr/local/bin/; \
            fi; \
            rm -rf /tmp/*; \
            apk del --no-cache .deps

