FROM alpine:latest

SHELL ["sh", "-euxvc"]

ONBUILD ARG CMAKE_VERSION=3.11.0
ONBUILD RUN apk add --no-cache --virtual .cmake-deps unzip curl ca-certificates; \
            curl -sLO https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz; \
            curl -sLo cmake.txt https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-SHA-256.txt; \
            grep 'Linux-x86_64\.tar\.gz' cmake.txt | sha256sum -c - > /dev/null; \
            tar xf /cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz; \
            mv /cmake-${CMAKE_VERSION}-Linux-x86_64 /cmake; \
            rm /cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz; \
            apk del .cmake-deps
