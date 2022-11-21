# syntax=docker/dockerfile:1.4
FROM vsiri/recipe:cuda as cuda
FROM vsiri/recipe:cudagl as cudagl
FROM vsiri/recipe:rocky as rocky
FROM redhat/ubi8
COPY --from=cuda /usr/local /usr/local
COPY --from=cudagl /usr/local /usr/local
COPY --from=rocky /usr/local /usr/local

RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility

CMD nvidia-smi