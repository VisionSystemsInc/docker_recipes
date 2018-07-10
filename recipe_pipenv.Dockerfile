FROM python:3.6.6-slim-stretch

SHELL ["bash", "-euxvc"]

ONBUILD RUN apt-get update; \
            # binutils needed for objdump or else pyinstaller doesn't finish
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wget binutils; \
            rm -rf /var/lib/apt/lists/*

            # pyinstaller needs six, but it's not a dependency?
ONBUILD RUN pip install pyinstaller six

ONBUILD ARG PIPENV_VERSION=v2018.7.1
ONBUILD RUN wget -q "https://github.com/pypa/pipenv/archive/${PIPENV_VERSION}/pipenv-${PIPENV_VERSION}.tar.gz"; \
            tar xf pipenv-${PIPENV_VERSION}.tar.gz; \
            rm pipenv-${PIPENV_VERSION}.tar.gz; \
            cd pipenv-*; \
            # pip install .
            echo "from pipenv import cli; cli()" > /tmp/pipenv; \
            pyinstaller -p ./pipenv/patched/ \
                        -p ./pipenv/vendor/ \
                        --onefile \
                        /tmp/pipenv; \
            cp dist/pipenv /usr/local/bin/pipenv; \
            chmod 755 /usr/local/bin/pipenv; \
            cd ..; \
            rm -r pipenv-*