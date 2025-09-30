FROM vsiri/recipe:cuda AS cuda

FROM redhat/ubi8

# install CUDA
ENV CUDA_RECIPE_TARGET="devel"
COPY --from=cuda /usr/local /usr/local
RUN shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done;
