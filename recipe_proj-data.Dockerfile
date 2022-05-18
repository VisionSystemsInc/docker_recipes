# optionally install proj-data (over 500MB) useful for certain PROJ datum transformations
# https://github.com/OSGeo/PROJ-data
# Users may avoid this large install by alternatively using remotely hosted proj-data
# https://proj.org/usage/network.html
FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG PROJ_DATA_VERSION=
ONBUILD ARG PROJ_DATA_DIR="/usr/local/share/proj"
#No signature :(
ONBUILD RUN apk add --no-cache --virtual .deps curl ca-certificates; \
            mkdir -p "${PROJ_DATA_DIR}"; \
            cd "${PROJ_DATA_DIR}"; \
            if [ -n "${PROJ_DATA_VERSION-}" ]; then \
                TAR_FILE="proj-data-${PROJ_DATA_VERSION}.tar.gz"; \
                curl -fsSLO "https://download.osgeo.org/proj/${TAR_FILE}"; \
                tar -xf "${TAR_FILE}"; \
                rm "${TAR_FILE}"; \
            fi; \
            apk del .deps
