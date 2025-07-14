FROM debian:bookworm-20250630-slim

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN apt-get update -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
        ca-certificates curl ; \
    rm -rf /var/lib/apt/lists/*

ONBUILD ARG USE_MINICONDA=0
ONBUILD RUN if [ "${USE_MINICONDA}" = "1" ]; then \
              curl -fsSLo /mini.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; \
            else \
              curl -fsSLo /mini.sh https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh; \
            fi; \
            sh /mini.sh -b -p /conda -s; \
            rm /mini.sh

ONBUILD ARG PYTHON_VERSION=3.8.5
ONBUILD ARG PYTHON_INSTALL_DIR=/usr/local
ONBUILD RUN /conda/bin/conda create -y -p "${PYTHON_INSTALL_DIR}" "python==${PYTHON_VERSION}"
