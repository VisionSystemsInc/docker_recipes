FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.7.1
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD RUN apk add --no-cache wget; \
            mkdir -p /tmp/pipenv/; \
            wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/pipenv/get-pip.py; \
            apk del --no-cache wget

ONBUILD ARG PYTHON
ONBUILD RUN echo '#!/usr/bin/env sh' > /tmp/pipenv/get-pipenv; \
            echo 'set -eu; \
                  TMP_DIR="$(mktemp -d)"; \
                  : ${PYTHON:="$( (command -v python3 || command -v python || command -v python2) | head -n 1)"}; \
                  [ -n "${PYTHON}" ]; \
                  "${PYTHON}" /tmp/pipenv/get-pip.py --no-cache-dir -I --root "${TMP_DIR}" virtualenv; \
                  # In order to get python to use our custom root dir, we must set the PYTHONPATH to its
                  # site-packages directory. Unfortunately, when we ask site for the answer, it gives
                  # multiple answers. Just use them all
                  SITE_PACKAGES="$("${PYTHON}" -c "if True: \
                          import os, site; \
                          print('"'"':'"'"'.join([os.path.join('"'"'${TMP_DIR}'"'"',x.lstrip(os.path.sep)) \
                                  for x in site.getsitepackages()]))")"; \
                  # With PYTHONPATH set, we can ask pip where the scipts directory is (a find would also work)
                  SCRIPTS="$(PYTHONPATH="${SITE_PACKAGES}" "${PYTHON}" -c "if True: \
                          from pip._internal import locations; \
                          print(locations.distutils_scheme('"''"', root='"'"'${TMP_DIR}'"'"')['"'"'scripts'"'"'])")"; \
                  # Create a virtualenv and install pipenv into it
                  PYTHONPATH="${SITE_PACKAGES}" "${SCRIPTS}"/virtualenv '"${PIPENV_VIRTUALENV}"'; \
                  '"${PIPENV_VIRTUALENV}"'/bin/pip install --no-cache-dir pipenv=='"${PIPENV_VERSION}"'; \
                  ln -s '"${PIPENV_VIRTUALENV}"'/bin/pipenv /usr/local/bin/pipenv; \
                  rm -rf "${TMP_DIR}"' >> /tmp/pipenv/get-pipenv; \
            chmod 755 /tmp/pipenv/get-pipenv
