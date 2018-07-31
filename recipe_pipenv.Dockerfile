FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.7.1
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD RUN apk add --no-cache wget; \
            mkdir -p /tmp/pipenv/; \
            wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/pipenv/get-pip.py; \
            apk del --no-cache wget

ONBUILD RUN echo 'temp=$(mktemp -d); \
                  chmod u+x /tmp/pipenv/get-pip.py; \
                  /tmp/pipenv/get-pip.py --no-cache-dir -I --root "${temp}" virtualenv; \
                  OLD_PYTHONPATH="${PYTHONPATH}"; \
                  export PYTHONPATH="${temp}/$(python -c "import sysconfig; print(sysconfig.get_path('"'"'purelib'"'"'))")"; \
                  "$(dirname "$(dirname "$(dirname "${PYTHONPATH}")")")"/bin/virtualenv '"${PIPENV_VIRTUALENV}"'; \
                  export PYTHONPATH="${OLD_PYTHONPATH}"; \
                  '"${PIPENV_VIRTUALENV}"'/bin/pip install --no-cache-dir pipenv=='"${PIPENV_VERSION}"'; \
                  ln -s '"${PIPENV_VIRTUALENV}"'/bin/pipenv /usr/local/bin/pipenv; \
                  rm -rf "${temp}"' > /tmp/pipenv/get-pipenv
