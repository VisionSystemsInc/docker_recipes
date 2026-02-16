ARG VSI_RECIPE_REPO=vsiri/recipe

FROM ${VSI_RECIPE_REPO}:pipenv AS pipenv

FROM python:3.10
SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=pipenv /usr/local /usr/local
RUN ln -s "$(which python3)" /bar; \
    shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

ENV PIPENV_PIPFILE=/src/Pipfile

RUN mkdir -p /src/packages/abcd; \
    (cd /src/packages/abcd; "/foo/bin/fake_package" abcd); \
    echo -e '[packages]\nabcd = {editable = true, path = "./packages/abcd"}' >> /src/Pipfile; \
    "/foo/bin/pipenv" install;
