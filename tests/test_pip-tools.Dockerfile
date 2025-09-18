FROM vsiri/recipe:pip-tools AS pip-tools

FROM python:3.11
SHELL ["/usr/bin/env", "bash", "-euxvc"]

ARG PIP_TOOLS_VERSION=
RUN pip3 install pip-tools${PIP_TOOLS_VERSION:+"==${PIP_TOOLS_VERSION}"}

COPY --from=pip-tools /usr/local /usr/local
RUN ln -s "$(which python3)" /bar; \
    shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
