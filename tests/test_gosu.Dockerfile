ARG VSI_RECIPE_REPO=vsiri/recipe

FROM ${VSI_RECIPE_REPO}:gosu AS gosu

FROM alpine:3.16.2

SHELL ["/usr/bin/env", "sh", "-euxvc"]

COPY --from=gosu /usr/local /usr/local

RUN if [ "$(gosu daemon id -u)" != 2 ]; then \
      exit 1; \
    fi
