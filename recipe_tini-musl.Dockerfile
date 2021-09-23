FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ADD tini /usr/local/bin/tini

ONBUILD ARG TINI_VERSION=v0.18.0
ONBUILD RUN apk add --no-cache --virtual .deps gnupg curl ca-certificates; \
            # download tini
            curl -fsSRLo /usr/local/bin/_tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-muslc-amd64; \
            chmod +x /usr/local/bin/tini /usr/local/bin/_tini; \
            # verify the signature
            curl -fsSLo /dev/shm/tini.asc https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-muslc-amd64.asc; \
            export GNUPGHOME=/dev/shm; \
            for server in $(shuf -e ha.pool.sks-keyservers.net \
                                    hkp://p80.pool.sks-keyservers.net:80 \
                                    keyserver.ubuntu.com \
                                    hkp://keyserver.ubuntu.com:80 \
                                    pgp.mit.edu) ; do \
                gpg --batch --keyserver "${server}" --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 && break || : ; \
            done; \
            gpg --batch --verify /dev/shm/tini.asc /usr/local/bin/_tini; \
            # cleanup to keep intermediate image samell
            apk del .deps