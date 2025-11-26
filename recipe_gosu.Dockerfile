FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG GOSU_VERSION=1.11
ONBUILD ARG GOSU_SKIP_GPG=0
ONBUILD RUN apk add --no-cache --virtual .deps curl dpkg gnupg openssl; \
            # download gosu
            dpkgArch="$(dpkg --print-architecture | awk -F- '{print $NF}')"; \
            curl -fsSRLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}"; \
            chmod +x /usr/local/bin/gosu; \
            # verify the signature
            if [ "${GOSU_SKIP_GPG}" != "1" ]; then \
                curl -fsSLo /dev/shm/gosu.asc "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}.asc"; \
                export GNUPGHOME=/dev/shm; \
                for server in $(shuf -e ha.pool.sks-keyservers.net \
                                        hkp://p80.pool.sks-keyservers.net:80 \
                                        keys.openpgp.org \
                                        hkp://keys.openpgp.org:80 \
                                        keyserver.ubuntu.com \
                                        hkp://keyserver.ubuntu.com:80 \
                                        pgp.mit.edu \
                                        hkp://pgp.mit.edu:80 ); do \
                    gpg --batch --keyserver "${server}" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || :; \
                done; \
                gpg --batch --verify /dev/shm/gosu.asc /usr/local/bin/gosu; \
            fi; \
            # verify that the binary works
            gosu nobody true; \
            # cleanup
            apk del .deps
