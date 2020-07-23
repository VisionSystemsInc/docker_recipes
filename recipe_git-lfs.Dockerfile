FROM alpine:3.11

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ONBUILD ARG GIT_LFS_VERSION=v2.11.0

ADD 30_install_git-lfs /usr/local/share/just/container_build_patch/30_install_git-lfs

ONBUILD RUN apk add --no-cache --virtual .deps ca-certificates curl; \
            WORKDIR="/tmp"; \
            curl -fsSLo "${WORKDIR}/lfs.tar.gz" "https://github.com/git-lfs/git-lfs/releases/download/${GIT_LFS_VERSION}/git-lfs-linux-amd64-$GIT_LFS_VERSION.tar.gz"; \
            tar zxf "${WORKDIR}/lfs.tar.gz" -C ${WORKDIR} git-lfs; \
            mv "${WORKDIR}/git-lfs" /usr/local/bin/; \
            apk del --no-cache .deps; \
            chmod +x /usr/local/share/just/container_build_patch/30_install_git-lfs