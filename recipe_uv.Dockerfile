FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

COPY --chmod=755 30_get-uv /usr/local/share/just/container_build_patch/
COPY --chmod=755 pip-fake /usr/local/bin/

ONBUILD ARG UV_VERSION
ONBUILD ARG RECIPE_UV_VERSION="${UV_VERSION}"

ONBUILD RUN apk add --no-cache --virtual .deps curl ca-certificates; \
            URL="https://astral.sh/uv/${RECIPE_UV_VERSION}/install.sh"; \
            FILE="/usr/local/share/just/temp/uv_install.sh"; \
            mkdir -p "$(dirname "${FILE}")"; \
            curl -fsSRL "${URL}" -o "${FILE}";
