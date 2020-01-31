FROM alpine:3.11

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.11.26
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD ARG PIPENV_PYTHON
ADD get-pipenv /usr/local/share/just/container_build_patch/30_get-pipenv
# Save the arg values in the script, for use later when get-pipenv is called
ONBUILD RUN sed -i -e "3a: \${PIPENV_PYTHON:=${PIPENV_PYTHON-}}" \
                   -e "3a: \${PIPENV_VERSION:=${PIPENV_VERSION}}" \
                   -e "3a: \${PIPENV_VIRTUALENV:=${PIPENV_VIRTUALENV}}" \
                   /usr/local/share/just/container_build_patch/30_get-pipenv; \
            chmod 755 /usr/local/share/just/container_build_patch/30_get-pipenv
