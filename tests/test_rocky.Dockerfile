ARG VSI_RECIPE_REPO=vsiri/recipe

FROM ${VSI_RECIPE_REPO}:rocky as rocky

FROM redhat/ubi8
COPY --from=rocky /usr/local /usr/local
RUN test -e /usr/local/share/just/container_build_patch/10_sideload_rocky
RUN shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
RUN ! test -e /usr/local/share/just/container_build_patch/10_sideload_rocky

RUN dnf install -y --enablerepo=rocky-appstream telnet # This line is just an example