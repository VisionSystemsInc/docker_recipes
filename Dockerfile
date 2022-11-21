# syntax=docker/dockerfile:1.4
FROM vsiri/recipe:cuda as cuda
FROM vsiri/recipe:cudagl as cudagl

FROM redhat/ubi8

COPY --from=cuda /usr/local /usr/local
COPY --from=cudagl /usr/local /usr/local
# Only needs to be run once for all recipes
RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

# Required for this recipe
ENV NVIDIA_VISIBLE_DEVICES=all
# NVIDIA_DRIVER_CAPABILITIES is optional, but not setting it results in compute,utility
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
