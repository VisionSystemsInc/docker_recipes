# syntax=docker/dockerfile:1.4
FROM vsiri/recipe:cuda as cuda
FROM vsiri/recipe:rocky as rocky
FROM redhat/ubi8
COPY --from=cuda /usr/local /usr/local
COPY --from=rocky /usr/local /usr/local

RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

CMD nvidia-smi