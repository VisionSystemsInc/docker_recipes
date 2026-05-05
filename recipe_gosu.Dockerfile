FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG GOSU_VERSION=1.11
ONBUILD ARG GOSU_SKIP_GPG=0
ONBUILD COPY --chmod=755 verify_gpg.sh /usr/local/bin
ONBUILD RUN apk add --no-cache --virtual .deps curl dpkg gnupg openssl; \
            # download gosu
            dpkgArch="$(dpkg --print-architecture | awk -F- '{print $NF}')"; \
            curl -fsSRLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}"; \
            chmod +x /usr/local/bin/gosu; \
            # verify the signature
            SKIP_GPG_VERIFY=${GOSU_SKIP_GPG-} verify_gpg.sh \
                /usr/local/bin/gosu \
                "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}.asc" \
                B42F6819007F00F88E364FD4036A9C25BF357DD4; \
            # verify that the binary works
            gosu nobody true; \
            # cleanup
            apk del .deps
