# syntax=docker/dockerfile:1.4
FROM scratch

ADD --chmod=755 vsi::pip-tools::* /usr/local/bin/
