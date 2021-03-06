FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ENV GET_PIPENV_FILE="/usr/local/share/just/container_build_patch/30_get-pipenv"
ADD 30_get-pipenv "${GET_PIPENV_FILE}"
RUN chmod 755 "${GET_PIPENV_FILE}"

ONBUILD ARG PIPENV_PYTHON
ONBUILD ARG RECIPE_PIPENV_PYTHON="${PIPENV_PYTHON}"

ONBUILD ARG PIPENV_VERSION
ONBUILD ARG RECIPE_PIPENV_VERSION="${PIPENV_VERSION}"

ONBUILD ARG PIPENV_VIRTUALENV
ONBUILD ARG RECIPE_PIPENV_VIRTUALENV="${PIPENV_VIRTUALENV:-/usr/local/pipenv}"

ONBUILD ARG VIRTUALENV_VERSION
ONBUILD ARG RECIPE_VIRTUALENV_VERSION="${VIRTUALENV_VERSION}"

# Save the arg values in the script, for use later when get-pipenv is called
ONBUILD RUN sed -i -e "3a: \${RECIPE_PIPENV_PYTHON:=${RECIPE_PIPENV_PYTHON}}" \
                   -e "3a: \${RECIPE_PIPENV_VERSION:=${RECIPE_PIPENV_VERSION}}" \
                   -e "3a: \${RECIPE_PIPENV_VIRTUALENV:=${RECIPE_PIPENV_VIRTUALENV}}" \
                   -e "3a: \${RECIPE_VIRTUALENV_VERSION:=${RECIPE_VIRTUALENV_VERSION}}" \
                   "${GET_PIPENV_FILE}"
