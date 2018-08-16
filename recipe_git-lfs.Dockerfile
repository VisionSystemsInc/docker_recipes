FROM alpine:latest

SHELL ["sh", "-euxvc"]

ONBUILD ARG GIT_LFS_VERSION=2.5.1

ONBUILD RUN apk add --update --no-cache --virtual .deps ca-certificates curl && \
            WORKDIR="/tmp" && \
            curl -Lo $WORKDIR/lfs.tar.gz https://github.com/github/git-lfs/releases/download/v$GIT_LFS_VERSION/git-lfs-linux-amd64-$GIT_LFS_VERSION.tar.gz && \
            tar zxvf $WORKDIR/lfs.tar.gz -C $WORKDIR --strip-components=1 && \
            mv $WORKDIR/git-lfs /usr/local/bin && \
            rm -rf $WORKDIR/* && \
            apk del .deps