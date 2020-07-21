FROM vsiri/recipe:pipenv AS pipenv

FROM python:3
SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=pipenv /usr/local /usr/local
RUN ln -s "$(which python3)" /bar; \
    for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
