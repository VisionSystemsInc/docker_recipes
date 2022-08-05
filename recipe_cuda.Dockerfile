# syntax=docker/dockerfile:1.4

FROM alpine:3.11.8

RUN apk add --no-cache bash gettext
SHELL ["/usr/bin/env", "bash", "-euxvc"]

# More up to date than our traditional method, since nvidia can't get enough out of changing GPG keys
ADD https://gitlab.com/nvidia/container-images/cuda/-/archive/master/cuda-master.tar.gz /
RUN tar xf /cuda-master.tar.gz; \
    mv /cuda-master /cuda; \
    rm /cuda-master.tar.gz
# RUN apk add --no-cache --virtual .deps curl ca-certificates; \
#     curl -fsSLO https://gitlab.com/nvidia/container-images/cuda/-/archive/master/cuda-master.tar.gz; \
#     tar xf /cuda-master.tar.gz; \
#     mv /cuda-master /cuda; \
#     rm /cuda-master.tar.gz
#     apk del .deps

ADD 00_cuda_sanity_check /usr/local/share/just/root_run_patch/
ADD 10_load_cuda_env /usr/local/share/just/user_run_patch/
ADD 30_ldconfig 30_install_cuda /usr/local/share/just/container_build_patch/
RUN chmod 755 /usr/local/share/just/root_run_patch/00_cuda_sanity_check \
              /usr/local/share/just/container_build_patch/30_ldconfig
              /usr/local/share/just/container_build_patch/30_install_cuda; \
    chmod 644 /usr/local/share/just/user_run_patch/10_load_cuda_env

ONBUILD ARG CUDA_VERSION=11.7.0
ONBUILD ARG CUDNN_VERSION=
ONBUILD ARG CUDA_RECIPE_TARGET=runtime

ONBUILD RUN set -o pipefail; \
            apk add --no-cache --virtual .deps curl ca-certificates; \
            mkdir -p /usr/local/share/just/info/cuda/keys; \
            function parse_envvar(){ \
              awk '!x[$2]++' "${1}" | sed -nE '/^ENV/s/ENV ([^ ]*) /\1=/p'; \
            }; \
            function parse_os(){ \
              parse_envvar "${1}/base/Dockerfile" > "/usr/local/share/just/info/cuda/10_cudaenv_${2}"; \
              parse_envvar "${1}/runtime/Dockerfile" > "/usr/local/share/just/info/cuda/12_cudaenv_${2}"; \
              parse_envvar "${1}/devel/Dockerfile" > "/usr/local/share/just/info/cuda/14_cudaenv_${2}"; \
              if [ -n "${CUDNN_VERSION:+set}" ]; then \
                # If this errors during build, you probably set CUDNN_VERSION wrong
                parse_envvar "${1}/runtime/cudnn${CUDNN_VERSION}/Dockerfile" > "/usr/local/share/just/info/cuda/13_cudaenv_${2}"; \
                parse_envvar "${1}/devel/cudnn${CUDNN_VERSION}/Dockerfile" > "/usr/local/share/just/info/cuda/13_cudaenv_${2}"; \
              fi; \
            }; \
            # Env Vars
            # Currently all the fedoras use the same vars, so the first one is good enough
            for rhel in ubi10 ubi9 ubi8 ubi7 rockylinux10 rockylinux9 rockylinux8 centos7; do \
              if [ -d "/cuda/dist/${CUDA_VERSION}/${rhel}" ]; then \
                parse_os "/cuda/dist/${CUDA_VERSION}/${rhel}" rhel; \
                break; \
              fi; \
            done; \
            # Ubuntus
            for ubuntu in ubuntu2804 ubuntu2604 ubuntu2404 ubuntu2204 ubuntu2004 ubuntu1804; do \
              if [ -d "/cuda/dist/${CUDA_VERSION}/${ubuntu}" ]; then \
                parse_os "/cuda/dist/${CUDA_VERSION}/${ubuntu}" ubuntu; \
                break; \
              fi; \
            done; \
            # get GPG keys
            rhel_keys=($(grep -hr 'rhel.*\.pub' /cuda/dist/[0-9]* | sed -E 's|.*(https://[^ ]*).*|\1|' | sort -u)); \
            ubuntu_keys=($(grep -hr 'ubuntu.*\.pub' /cuda/dist/[0-9]* | sed -E 's|.*(https://[^ ]*).*|\1|' | sort -u)); \
            # even though there are multiple URLs, they are all the same key. They get
            # updated together
            export NVARCH=x86_64; \
            for rhel_key in "${rhel_keys[@]}"; do \
              file=/usr/local/share/just/info/cuda/keys/RPM-GPG-KEY-NVIDIA; \
              if [ ! -f "${file}" ]; then \
                rhel_key="$(echo "${rhel_key}" | envsubst)"; \
                curl -fsSL "${rhel_key}" |  sed '/^Version/d' > "${file}"; \
              fi; \
            done; \
            for ubuntu_key in "${ubuntu_keys[@]}"; do \
              file=/usr/local/share/just/info/cuda/keys/$(basename "${ubuntu_key}"); \
              if [ ! -f "${file}" ]; then \
                ubuntu_key="$(echo "${ubuntu_key}" | envsubst)"; \
                curl -fsSL "${ubuntu_key}" > "${file}"; \
              fi; \
            done; \
            apk del .deps
            # # Make a common file to pass the build args
            # file=/usr/local/share/just/info/cuda/00_common; \
            # echo ": \${CUDA_RECIPE_TARGET:=${CUDA_RECIPE_TARGET}}" > "${file}"; \
            # echo ": \${CUDA_VERSION:=${CUDA_VERSION}}" >> "${file}"; \
            # echo ": \${CUDNN_VERSION:=${CUDNN_VERSION}}" >> "${file}"

ONBUILD COPY <<EOF /usr/local/share/just/info/cuda/00_cuda_common
: \${CUDA_RECIPE_TARGET:=${CUDA_RECIPE_TARGET}}
: \${CUDA_VERSION:=${CUDA_VERSION}}
: \${CUDNN_VERSION:=${CUDNN_VERSION}}
EOF
