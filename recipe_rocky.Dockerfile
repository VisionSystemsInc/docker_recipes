# Once we move to buildkit
# FROM scratch
# ADD --chmod=755 10_sideload_rocky /usr/local/share/just/container_build_patch/

FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

ENV ROCKY_FILE="/usr/local/share/just/container_build_patch/10_sideload_rocky"
ADD 10_sideload_rocky "${ROCKY_FILE}"
RUN chmod 755 "${ROCKY_FILE}"