ARG GO_VERSION=1.26.5
FROM golang:${GO_VERSION}-trixie

SHELL ["/usr/bin/env", "bash", "-euxvc"]

ONBUILD RUN DEBIAN_FRONTEND=noninteractive apt-get install --update -y --no-install-recommends \
          file; \
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
            try /usr/local/bin/gosu nobody ls -l /proc/self/fd
