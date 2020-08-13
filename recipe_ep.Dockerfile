FROM alpine:3.11

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG EP_VERSION=1.0.0-RC1
#No signature :(
ONBUILD RUN apk add --no-cache --virtual .deps curl ca-certificates; \
            curl -fsSRLo /usr/local/bin/ep https://github.com/kreuzwerker/envplate/releases/download/${EP_VERSION}/ep-linux; \
            chmod +x /usr/local/bin/ep; \
            apk del .deps
