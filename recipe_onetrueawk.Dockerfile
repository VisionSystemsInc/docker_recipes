FROM alpine:3.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD RUN apk add --no-cache gcc make curl bison libc-dev
ONBUILD ARG ONETRUEAWK_VERSION=89354cc23057158fa4feb566e46513ca5c44ac3b
ONBUILD RUN curl -Lf https://github.com/onetrueawk/awk/archive/${ONETRUEAWK_VERSION}.tar.gz -o awk.tgz; \
            tar xzf awk.tgz; \
            cd /awk-*; \
            make CFLAGS="-O2 -static"; \
            install -m 0755 a.out /usr/local/bin/awk
