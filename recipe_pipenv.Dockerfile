FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.11.26
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD ARG PIPENV_PYTHON
ADD get-pipenv /tmp/pipenv/get-pipenv
# Save the arg values in the script, for use later when get-pipenv is called
ONBUILD RUN sed -i -e "3a: \${PIPENV_PYTHON:=${PIPENV_PYTHON-}}" \
                   -e "3a: \${PIPENV_VERSION:=${PIPENV_VERSION}}" \
                   -e "3a: \${PIPENV_VIRTUALENV:=${PIPENV_VIRTUALENV}}" \
                   /tmp/pipenv/get-pipenv; \
            chmod 755 /tmp/pipenv/get-pipenv
