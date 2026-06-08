ARG VSI_RECIPE_REPO=vsiri/recipe

FROM ${VSI_RECIPE_REPO}:uv AS uv

FROM redhat/ubi9
SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=uv /usr/local /usr/local
RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done;

RUN mkdir -p /foo; cd /foo; \
    uv init --python 3.13.12; uv add "numpy==2.4.5"
