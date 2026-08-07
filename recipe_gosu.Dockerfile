FROM debian:trixie

SHELL ["/usr/bin/env", "bash", "-euxvc"]

# TODO: Should golang be a separate recipe?
COPY verify_gpg.sh /usr/local/bin/
ONBUILD ENV PATH /usr/local/go/bin:$PATH
ONBUILD ARG GOLANG_VERSION=1.26.5
ONBUILD ARG GOLANG_SKIP_GPG=0
ONBUILD RUN DEBIAN_FRONTEND=noninteractive apt-get install --update -y --no-install-recommends \
              curl ca-certificates gpg dirmngr; \
            url="https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz"; \
            curl -fsSL "${url}" -o /go.tgz; \
            SKIP_GPG_VERIFY=${GOLANG_SKIP_GPG-} \
              # For some reason, letting it pick from the full list mostly fails.
              GPG_SERVERS="keyserver.ubuntu.com hkp://keyserver.ubuntu.com:80" \
              # use bash because debian's sh is too strict
              bash verify_gpg.sh \
                /go.tgz \
                "${url}.asc" \
                'EB4C1BFD4F042F6DDDCCEC917721F63BD38B4796' \
                '2F528D36D67B69EDF998D85778BD65473CB3BD13'; \
                tar -C /usr/local -xzf /go.tgz; \
            rm /go.tgz*; \
            go version; \
            DEBIAN_FRONTEND=noninteractive apt-get remove --auto-remove -y \
              curl ca-certificates gpg dirmngr; \
            rm -r /var/lib/apt/lists/*

ONBUILD RUN DEBIAN_FRONTEND=noninteractive apt-get install --update -y --no-install-recommends \
              g++ \
              gcc \
              libc6-dev \
              make \
              pkg-config; \
            rm -r /var/lib/apt/lists/*
ONBUILD ENV GOTOOLCHAIN=local
ONBUILD ENV GOPATH /go

ONBUILD RUN DEBIAN_FRONTEND=noninteractive apt-get install --update -y --no-install-recommends \
              file \
              git; \
            rm -r /var/lib/apt/lists/*

ONBUILD RUN mkdir -p /go/src/github.com/tianon/gosu

ONBUILD WORKDIR /go/src/github.com/tianon/gosu

ONBUILD ARG GOSU_VERSION=1.19
ONBUILD RUN git clone https://github.com/tianon/gosu .; \
            git checkout "${GOSU_VERSION}"

# disable CGO for ALL THE THINGS (to help ensure no libc)
ONBUILD ENV CGO_ENABLED=0
ONBUILD RUN go mod download

ONBUILD RUN set -Eeuo pipefail -xv; \
            cd /go/src/github.com/tianon/gosu; \
            # note: we cannot add "-s" here because then "govulncheck" does not work (see SECURITY.md); the ~0.2MiB increase (as of 2022-12-16, Go 1.18) is worth it
            go build -v -trimpath -ldflags '-d -w' -buildvcs=true \
                     -o /usr/local/bin/gosu github.com/tianon/gosu; \
            if go version -m /usr/local/bin/gosu |& tee "/proc/$$/fd/1" | grep "(devel)" >&2; then exit 1; fi; \
            file /usr/local/bin/gosu; \
            # there's a fun QEMU + Go 1.18+ bug that causes our binaries (especially on ARM arches) to hang indefinitely *sometimes*, hence the "timeout" and looping here
            try() { for (( i = 0; i < 30; i++ )); do if timeout 1s "$@"; then return 0; fi; done; return 1; }; \
            try /usr/local/bin/gosu --version; \
            try /usr/local/bin/gosu nobody id; \
            try /usr/local/bin/gosu nobody ls -l /proc/self/fd; \
            # We are done with go now, remove it so that it is not copied into any final images
            rm -rf /usr/local/go

# ONBUILD RUN curl -L https://github.com/tianon/gosu/releases/download/1.19/gosu-arm64 -o /usr/bin/gosu-amd64; \
#             chmod 755 /usr/bin/gosu-amd64