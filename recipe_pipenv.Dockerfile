FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.7.1
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD RUN apk add --no-cache wget; \
            mkdir -p /tmp/pipenv/; \
            wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/pipenv/get-pip.py; \
            apk del --no-cache wget

ONBUILD RUN echo '#!/usr/bin/env python' > /tmp/pipenv/get-pipenv; \
            echo "import os, sys, subprocess as sp, tempfile, glob, sysconfig" >> /tmp/pipenv/get-pipenv; \
            echo "try:" >> /tmp/pipenv/get-pipenv; \
            echo "  x=tempfile.TemporaryDirectory()" >> /tmp/pipenv/get-pipenv; \
            echo "  temp=x.name" >> /tmp/pipenv/get-pipenv; \
            echo "except:" >> /tmp/pipenv/get-pipenv; \
            echo "  temp=tempfile.mkdtemp()" >> /tmp/pipenv/get-pipenv; \
            echo "sp.Popen([sys.executable, os.path.dirname(os.path.realpath(__file__))+'/get-pip.py', '--no-cache-dir', '-I', '--root', temp, 'virtualenv']).wait()" >> /tmp/pipenv/get-pipenv; \
            echo "os.environ['PYTHONPATH'] = glob.glob(os.path.join(temp, sysconfig.get_path('purelib').lstrip(os.path.sep)))[0]" >> /tmp/pipenv/get-pipenv; \
            echo "d='${PIPENV_VIRTUALENV}'" >> /tmp/pipenv/get-pipenv; \
            echo "sp.Popen([sys.executable, os.path.join(temp, os.path.dirname(os.path.dirname(os.path.dirname(sysconfig.get_path('purelib').lstrip(os.path.sep)))), 'bin/virtualenv'), '${PIPENV_VIRTUALENV}']).wait()" >> /tmp/pipenv/get-pipenv; \
            echo "os.environ.pop('PYTHONPATH')" >> /tmp/pipenv/get-pipenv; \
            echo "sp.Popen(['${PIPENV_VIRTUALENV}/bin/pip', 'install', '--no-cache-dir', 'pipenv==${PIPENV_VERSION}']).wait()" >> /tmp/pipenv/get-pipenv; \
            echo "os.symlink('${PIPENV_VIRTUALENV}/bin/pipenv', '/usr/local/bin/pipenv')" >> /tmp/pipenv/get-pipenv; \
            echo "try:" >> /tmp/pipenv/get-pipenv; \
            echo "  del(x)" >> /tmp/pipenv/get-pipenv; \
            echo "except:" >> /tmp/pipenv/get-pipenv; \
            echo "  import shutil" >> /tmp/pipenv/get-pipenv; \
            echo "  shutil.rmtree(temp)" >> /tmp/pipenv/get-pipenv
