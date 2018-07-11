FROM alpine:3.7

SHELL ["sh", "-euxvc"]

ONBUILD ARG PIPENV_VERSION=2018.7.1
ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
ONBUILD RUN apk add --no-cache wget; \
            mkdir -p /tmp/pipenv/; \
            wget -q https://bootstrap.pypa.io/get-pip.py -O /tmp/pipenv/get-pip.py; \
            apk del --no-cache wget

ONBUILD RUN echo '#!/usr/bin/env python' > /tmp/pipenv/getpipenv; \
            echo "import os, sys, subprocess as sp, tempfile, glob" >> /tmp/pipenv/getpipenv; \
            echo "x=tempfile.TemporaryDirectory()" >> /tmp/pipenv/getpipenv; \
            echo "sp.Popen([sys.executable, os.path.dirname(os.path.realpath(__file__))+'/get-pip.py', '--no-cache-dir', '-I', '--root', x.name, 'virtualenv']).wait()" >> /tmp/pipenv/getpipenv; \
            echo "os.environ['PYTHONPATH'] = glob.glob(x.name+'/usr/local/lib/python*/*-packages')[0]" >> /tmp/pipenv/getpipenv; \
            echo "d='${PIPENV_VIRTUALENV}'" >> /tmp/pipenv/getpipenv; \
            echo "sp.Popen([sys.executable, x.name+'/usr/local/bin/virtualenv', '--always-copy', '${PIPENV_VIRTUALENV}']).wait()" >> /tmp/pipenv/getpipenv; \
            echo "os.environ.pop('PYTHONPATH')" >> /tmp/pipenv/getpipenv; \
            echo "sp.Popen(['${PIPENV_VIRTUALENV}/bin/pip', 'install', '--no-cache-dir', 'pipenv==${PIPENV_VERSION}']).wait()" >> /tmp/pipenv/getpipenv; \
            echo "os.symlink('${PIPENV_VIRTUALENV}/bin/pipenv', '/usr/local/bin/pipenv')" >> /tmp/pipenv/getpipenv

# ONBUILD RUN echo '#!/usr/bin/env python' > /usr/local/bin/getpipenv; \
#             echo "import os, sys, subprocess as sp, tempfile, glob" >> /usr/local/bin/getpipenv; \
#             echo "try:" >> /usr/local/bin/getpipenv; \
#             echo "  import urllib2 as u" >> /usr/local/bin/getpipenv; \
#             echo "except:" >> /usr/local/bin/getpipenv; \
#             echo "  import urllib.request as u" >> /usr/local/bin/getpipenv; \
#             echo "x=tempfile.TemporaryDirectory()" >> /usr/local/bin/getpipenv; \
#             echo "p=sp.Popen([sys.executable, '-', '--no-cache-dir', '-I', '--root', x.name, 'virtualenv'], stdin=sp.PIPE)" >> /usr/local/bin/getpipenv; \
#             echo "p.communicate(u.urlopen('https://bootstrap.pypa.io/get-pip.py').read())" >> /usr/local/bin/getpipenv; \
#             echo "p.wait()" >> /usr/local/bin/getpipenv; \
#             echo "os.environ['PYTHONPATH'] = glob.glob(x.name+'/usr/local/lib/python*/*-packages')[0]" >> /usr/local/bin/getpipenv; \
#             echo "d='${PIPENV_VIRTUALENV}'" >> /usr/local/bin/getpipenv; \
#             echo "sp.Popen([sys.executable, x.name+'/usr/local/bin/virtualenv', '--always-copy', '${PIPENV_VIRTUALENV}']).wait()" >> /usr/local/bin/getpipenv; \
#             echo "os.environ.pop('PYTHONPATH')" >> /usr/local/bin/getpipenv; \
#             echo "sp.Popen(['${PIPENV_VIRTUALENV}/bin/pip', 'install', '--no-cache-dir', 'pipenv==${PIPENV_VERSION}']).wait()" >> /usr/local/bin/getpipenv; \
#             echo "os.symlink('${PIPENV_VIRTUALENV}/bin/pipenv', '/usr/local/bin/pipenv')" >> /usr/local/bin/getpipenv

# NONE of these other attempts will work!

# This is a tricky recipe. In order for virtualenv recipes to work
# 1) The virtualenv directory must be the same in recipe and destination
# 2) The python executable must be statically linked, or else moving it to
#    another image will fail unless python is installed AND is the same minor
#    version
# 3) The python libraries need to be copied instead of symlinked, or else it
#    won't work unless python is installed in the exact same location on the
#    destination

# ONBUILD ARG PIPENV_VERSION=2018.7.1
# ONBUILD ARG PIPENV_VIRTUALENV=/usr/local/pipenv
# # ONBUILD RUN TMP_DIR="$(mktemp -d)"; \
# #             python3 <(wget -q https://bootstrap.pypa.io/get-pip.py -O -) --no-cache-dir -I --root "${TMP_DIR}" virtualenv; \
# #             PYTHONPATH="$(cd "${TMP_DIR}"/usr/local/lib/python*/*-packages/; pwd)" "${TMP_DIR}/usr/local/bin/virtualenv" --always-copy "${PIPENV_VIRTUALENV}"; \
# #             "${PIPENV_VIRTUALENV}/bin/pip" install --no-cache-dir pipenv==${PIPENV_VERSION}; \
# #             ln -s "${PIPENV_VIRTUALENV}/bin/pipenv" /usr/local/bin/pipenv

# ONBUILD RUN pip3 install --no-cache-dir virtualenv; \
#             virtualenv "${PIPENV_VIRTUALENV}"; \
#             "${PIPENV_VIRTUALENV}/bin/pip" install --no-cache-dir pipenv; \
#             cp -a /usr/local/lib/libpython3.6m.so.1.0 "${PIPENV_VIRTUALENV}/lib/"; \
#             cd "${PIPENV_VIRTUALENV}/bin"; \
#             mv python .python; \
#             rm python3 python3.6; \
#             echo '#!/usr/bin/env bash' > python; \
#             echo 'export LD_PRELOAD=/usr/local/pipenv/lib/libpython3.6m.so.1.0${LD_PRELOAD+:"${LD_PRELOAD}"}' >> python; \
#             echo 'exec /usr/local/pipenv/bin/.python ${@+"${@}"}' >> python; \
#             chmod 755 python; \
#             ln -s "${PIPENV_VIRTUALENV}/bin/pipenv" /usr/local/bin/pipenv