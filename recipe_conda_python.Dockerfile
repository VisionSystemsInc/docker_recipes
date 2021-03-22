FROM debian:buster-20210311-slim

SHELL ["/usr/bin/env", "bash", "-euxvc"]

RUN apt-get update -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
        ca-certificates curl ; \
    rm -rf /var/lib/apt/lists/* ;

RUN curl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh; \
    sh /Miniconda3-latest-Linux-x86_64.sh -b -p /conda -s; \
    rm /Miniconda3-latest-Linux-x86_64.sh

ONBUILD ARG PYTHON_VERSION=3.8.5
ONBUILD RUN /conda/bin/conda create -y -p "/usr/local/" "python==${PYTHON_VERSION}"
