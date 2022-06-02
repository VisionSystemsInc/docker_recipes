FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG CMAKE_VERSION=3.16.3
ONBUILD RUN apk add --no-cache --virtual .deps unzip curl ca-certificates; \
            minor=${CMAKE_VERSION%.*}; \
            major=${minor%.*}; \
            minor=${minor#*.}; \
            if [ "${major}" -gt "3" ] || [ "${major}" = "3" -a "${minor}" -ge "20" ]; then \
              os_name="linux-x86_64"; \
            else \
              os_name="Linux-x86_64"; \
            fi; \
            curl -fsSLRO "https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-${os_name}.tar.gz"; \
            curl -fsSLo cmake.txt "https://cmake.org/files/v${CMAKE_VERSION%.*}/cmake-${CMAKE_VERSION}-SHA-256.txt"; \
            grep "${os_name}\\.tar\\.gz" cmake.txt | sha256sum -c - > /dev/null; \
            tar xf "/cmake-${CMAKE_VERSION}-${os_name}.tar.gz"; \
            rm -r /usr/local/*; \
            mv "/cmake-${CMAKE_VERSION}-${os_name}"/* /usr/local/; \
            if [ -d "/usr/local/man" ]; then \
              mkdir -p /usr/local/share; \
              mv /usr/local/man /usr/local/share/; \
            fi; \
            rmdir "/cmake-${CMAKE_VERSION}-${os_name}"; \
            rm "/cmake-${CMAKE_VERSION}-${os_name}.tar.gz"; \
            apk del .deps
