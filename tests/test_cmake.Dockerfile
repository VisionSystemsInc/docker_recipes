FROM vsiri/recipe:cmake AS cmake

FROM vsiri/circleci:bash-glibc

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN apk add --no-cache git

COPY --from=cmake /usr/local /usr/local

RUN shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
