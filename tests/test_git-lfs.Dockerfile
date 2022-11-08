FROM vsiri/recipe:git-lfs AS git-lfs

FROM alpine:3.16.2

RUN apk add --no-cache git bash gcompat

SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=git-lfs /usr/local /usr/local
RUN shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
