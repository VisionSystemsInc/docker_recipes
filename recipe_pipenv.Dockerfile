FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD RUN apk add --no-cache --virtual .deps wget ca-certificates; \
            mkdir -p /tmp/pipenv/; \
            wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/pipenv/get-pip.py; \
            apk del --no-cache .deps

ONBUILD ARG PIPENV_VERSION=2018.11.14
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD ARG PIPENV_PYTHON
ADD get-pipenv /tmp/pipenv/get-pipenv
ONBUILD RUN sed -i -e "3a: \${PIPENV_PYTHON:=${PIPENV_PYTHON-}}" \
                   -e "3a: \${PIPENV_VERSION:=${PIPENV_VERSION}}" \
                   -e "3a: \${PIPENV_VIRTUALENV:=${PIPENV_VIRTUALENV}}" \
                   /tmp/pipenv/get-pipenv; \
            chmod 755 /tmp/pipenv/get-pipenv
