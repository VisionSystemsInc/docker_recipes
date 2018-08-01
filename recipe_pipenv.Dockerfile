FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.7.1
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD RUN apk add --no-cache wget; \
            mkdir -p /tmp/pipenv/; \
            wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/pipenv/get-pip.py; \
            apk del --no-cache wget

ONBUILD RUN echo 'TMP_DIR=$(mktemp -d); \
                  python /tmp/pipenv/get-pip.py --no-cache-dir -I --root "${TMP_DIR}" virtualenv; \
                  SITE_PACKAGES="${TMP_DIR}/$(python -c "import sysconfig; print(sysconfig.get_path('"'"'purelib'"'"'))")"; \
                  SCRIPTS="${TMP_DIR}/$(python -c "import sysconfig; print(sysconfig.get_path('"'"'scripts'"'"'))")"; \
                  PYTHONPATH="${SITE_PACKAGES}" "${SCRIPTS}/virtualenv" '"${PIPENV_VIRTUALENV}"'; \
                  '"${PIPENV_VIRTUALENV}"'/bin/pip install --no-cache-dir pipenv=='"${PIPENV_VERSION}"'; \
                  ln -s '"${PIPENV_VIRTUALENV}"'/bin/pipenv /usr/local/bin/pipenv; \
                  rm -rf "${TMP_DIR}"' > /tmp/pipenv/get-pipenv
