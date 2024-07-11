# syntax=docker/dockerfile:1.4

FROM alpine:3.11.8

RUN apk add --no-cache bash gettext
SHELL ["/usr/bin/env", "bash", "-euxvc"]

# This ADD can be commented out to skip the test
# ADD https://gitlab.com/api/v4/projects/2330984/repository/branches/master /cuda-main.json

ARG CUDA_REPO_REF=81682547e12c8807ebc5fa61ff4576510925a324
RUN if [ -f "/cuda-main.json" ]; then \
      new_main_ref="$(sed 's|.*"id":"\([^"]*\).*|\1|' /cuda-main.json)"; \
      rm /cuda-main.json; \
      if [ "${new_main_ref}" != "${CUDA_REPO_REF}" ]; then \
        mkdir -p /usr/local/share/just/user_run_patch/; \
        echo "echo 'Cuda recipe is out of date.' >&2" > /usr/local/share/just/user_run_patch/00_cuda_outdated_warning; \
        echo "echo 'Consider submitting a PR to this repo to update CUDA_REPO_REF(${CUDA_REPO_REF}) to ${new_main_ref}' >&2" >> /usr/local/share/just/user_run_patch/00_cuda_outdated_warning; \
        echo 'echo "Or delete $0"' >> /usr/local/share/just/user_run_patch/00_cuda_outdated_warning; \
        chmod 755 /usr/local/share/just/user_run_patch/00_cuda_outdated_warning; \
      fi; \
    fi; \
    apk add --no-cache --virtual .deps curl ca-certificates; \
    curl -fsSLO https://gitlab.com/nvidia/container-images/cuda/-/archive/${CUDA_REPO_REF}/cuda.tar.gz; \
    tar xf /cuda.tar.gz; \
    mv /cuda-* /cuda; \
    rm /cuda.tar.gz; \
    apk del .deps

ADD --chmod=755 00_cuda_sanity_check /usr/local/share/just/root_run_patch/
ADD --chmod=644 10_load_cuda_env /usr/local/share/just/user_run_patch/
ADD --chmod=755 30_ldconfig 30_install_cuda /usr/local/share/just/container_build_patch/

ONBUILD ARG CUDA_VERSION=11.7.0
ONBUILD ARG CUDNN_VERSION=
ONBUILD ARG CUDA_RECIPE_TARGET=runtime

ONBUILD RUN set -o pipefail; \
            apk add --no-cache --virtual .deps curl ca-certificates; \
            mkdir -p /usr/local/share/just/info/cuda/keys; \
            function parse_envvar(){ \
              # Uses awk to only find the unique names, based on the second
              # column, which in this case is the environment variable name. This
              # works how we want because the x86_64 variables always come first
              # in the cuda Dockerfiles.
              # E.g.: https://gitlab.com/nvidia/container-images/cuda/-/blob/55e68010c6ed48abce440d25fbc25af42d318a73/dist/11.4.0/ubuntu1804/runtime/Dockerfile
              awk '!x[$2]++' "${1}" | sed -nE '/^ENV/s/ENV ([^ ]*) /\1=/p'; \
            }; \
            function parse_os(){ \
              parse_envvar "${1}/base/Dockerfile" > "/usr/local/share/just/info/cuda/10_cudaenv_${2}"; \
              parse_envvar "${1}/runtime/Dockerfile" > "/usr/local/share/just/info/cuda/12_cudaenv_${2}"; \
              parse_envvar "${1}/devel/Dockerfile" > "/usr/local/share/just/info/cuda/14_cudaenv_${2}"; \
              if [ -n "${CUDNN_VERSION:+set}" ]; then \
                # If this errors during build, you probably set CUDNN_VERSION wrong
                parse_envvar "${1}/runtime/cudnn${CUDNN_VERSION}/Dockerfile" > "/usr/local/share/just/info/cuda/13_cudaenv_${2}"; \
                parse_envvar "${1}/devel/cudnn${CUDNN_VERSION}/Dockerfile" >> "/usr/local/share/just/info/cuda/13_cudaenv_${2}"; \
              fi; \
            }; \
            # Env Vars
            # Currently all the fedoras use the same vars, so the first file found is good enough
            for rhel in ubi10 ubi9 ubi8 rockylinux10 rockylinux9 rockylinux8; do \
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

ONBUILD COPY <<EOF /usr/local/share/just/info/cuda/00_cuda_common
: \${CUDA_RECIPE_TARGET:=${CUDA_RECIPE_TARGET}}
: \${CUDA_VERSION:=${CUDA_VERSION}}
: \${CUDNN_VERSION:=${CUDNN_VERSION}}
EOF
