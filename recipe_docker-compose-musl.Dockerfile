ARG ALPINE_VERSION=3.8
FROM alpine:${ALPINE_VERSION}

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG DOCKER_COMPOSE_VERSION=1.24.1
ONBUILD ARG DOCKER_COMPOSE_VIRTUALENV=/usr/local/docker-compose

ONBUILD RUN apk add --no-cache \
                    --virtual .deps python3 python3-dev musl-dev libc-dev gcc \
                              libffi-dev openssl-dev make \
                              curl ca-certificates; \
            pip3 install -U virtualenv; \
            virtualenv "${DOCKER_COMPOSE_VIRTUALENV}"; \
            "${DOCKER_COMPOSE_VIRTUALENV}"/bin/pip install docker-compose==1.24.1; \
            apk del .deps


# Even when this is built against alpine 3.4, it works down to 3.2
# Based on https://github.com/docker/compose/pull/6141
# RUN echo "WIP: does not work yet"; \
#     false

# RUN apk add --no-cache --virtual .deps curl git python3-dev binutils \
#       ca-certificates gcc zlib-dev \
#       musl-dev libc-dev pwgen libffi-dev openssl-dev make; \
#     # Update pip
#     python3 -m pip install --upgrade pip setuptools wheel; \
#     # Get docker-compose source
#     curl -fsLO "https://github.com/docker/compose/archive/${DOCKER_COMPOSE_VERSION}/docker-compose.tar.gz"; \
#     tar zxf docker-compose.tar.gz; \
#     # Customize Pyinstaller bootstrapper
#     cd compose-*; \
#       pip3 download -r requirements-build.txt --no-deps; \
#       tar xzf PyInstaller*.tar.gz; \
#       cd PyInstaller-*/bootloader; \
#         python3 ./waf configure --no-lsb all; \
#         cd ..; \
#           python3 setup.py bdist_wheel; \
#           mv dist/*.whl /; \
#           cd ..; \
#       rm -rf PyInstaller*; \
#       pip install tox==2.1.1; \
#       tox -e py35 --notest; \
#       .tox/py35/bin/pip install /*.whl; \
#       echo unknown > compose/GITSHA; \
#       .tox/py35/bin/pyinstaller docker-compose.spec; \
#       mv dist/docker-compose /usr/local/bin/; \
#       cd ..; \
#     rm -rf docker-compose.tar.gz compose-* *.whl; \
#     apk del .deps
#     #
#     # /usr/local/bin/docker-compose --version
