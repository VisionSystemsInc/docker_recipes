# syntax=docker/dockerfile:1.4
FROM scratch

ADD --chmod=755 pip-* /usr/local/bin/
