FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

COPY tini verify_gpg.sh /usr/local/bin/

ONBUILD ARG TINI_VERSION=v0.18.0
ONBUILD ARG TINI_SKIP_GPG=0
ONBUILD RUN apk add --no-cache --virtual .deps gnupg curl ca-certificates; \
            # download tini
            curl -fsSRLo /usr/local/bin/_tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini; \
            chmod +x /usr/local/bin/_tini /usr/local/bin/tini; \
            # verify the signature
            SKIP_GPG_VERIFY=${TINI_SKIP_GPG-} verify_gpg.sh \
              /usr/local/bin/_tini \
              https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc \
              595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7; \
            # cleanup to keep intermediate image samell
            apk del .deps