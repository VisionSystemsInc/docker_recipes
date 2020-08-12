FROM alpine:3.11

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG NINJA_VERSION=v1.10.0
#No signature :(
ONBUILD RUN apk add --no-cache --virtual .deps unzip curl ca-certificates; \
            cd /usr/local/bin; \
            curl -fsSLo ninja-linux.zip https://github.com/ninja-build/ninja/releases/download/${NINJA_VERSION}/ninja-linux.zip; \
            unzip ninja-linux.zip; \
            chmod +x /usr/local/bin/ninja; \
            rm ninja-linux.zip; \
            apk del .deps
