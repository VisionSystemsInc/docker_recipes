FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG CMAKE_VERSION=3.16.3
ONBUILD RUN apk add --no-cache --virtual .deps unzip curl ca-certificates; \
            curl -fsSLRO https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz; \
            curl -fsSLo cmake.txt https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-SHA-256.txt; \
            grep 'Linux-x86_64\.tar\.gz' cmake.txt | sha256sum -c - > /dev/null; \
            tar xf /cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz; \
            rm -r /usr/local/*; \
            mv /cmake-${CMAKE_VERSION}-Linux-x86_64/* /usr/local/; \
            rmdir /cmake-${CMAKE_VERSION}-Linux-x86_64; \
            rm /cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz; \
            apk del .deps
