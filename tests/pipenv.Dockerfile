FROM vsiri/recipe:pipenv AS pipenv

FROM python:3
SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=pipenv /tmp/pipenv /tmp/pipenv
RUN /tmp/pipenv/get-pipenv; \
    rm -r /tmp/pipenv; \
    pipenv --version