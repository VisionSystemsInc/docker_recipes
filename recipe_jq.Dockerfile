FROM alpine:3.8

SHELL ["sh", "-euxvc"]

ONBUILD ARG JQ_VERSION=1.5
#No signature :(
ONBUILD RUN apk add --no-cache --virtual .deps curl ca-certificates; \
            curl -sLo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64; \
            chmod +x /usr/local/bin/jq; \
            apk del .deps
