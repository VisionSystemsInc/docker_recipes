FROM vsiri/recipe:rocky as rocky
FROM redhat/ubi8
COPY --from=rocky /usr/local /usr/local
RUN shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

RUN dnf install -y --enablerepo=rocky-appstream telnet # This line is just an example