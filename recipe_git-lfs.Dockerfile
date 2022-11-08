FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG GIT_LFS_VERSION=v3.2.0

ADD 30_install_git-lfs /usr/local/share/just/container_build_patch/30_install_git-lfs

ONBUILD RUN apk add --no-cache --virtual .deps ca-certificates curl; \
            WORKDIR="/tmp/lfs"; \
            mkdir -p "${WORKDIR}"; \
            curl -fsSLo "${WORKDIR}/lfs.tar.gz" "https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/git-lfs-linux-amd64-${GIT_LFS_VERSION}.tar.gz"; \
            # They change the format of the tarball too much, but this'll work
            # more generically by looking for a file named "git-lfs" exactly
            tar zxf "${WORKDIR}/lfs.tar.gz" -C "${WORKDIR}"; \
            find "${WORKDIR}" -type f -name git-lfs -exec mv {} /usr/local/bin/ \; ; \
            rm -r "${WORKDIR}"; \
            apk del --no-cache .deps; \
            chmod +x /usr/local/share/just/container_build_patch/30_install_git-lfs