FROM vsiri/recipe:pipenv AS pipenv

FROM python:3.8
SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=pipenv /usr/local /usr/local
RUN ln -s "$(which python3)" /bar; \
    shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
