# Docker recipes

[![CircleCI](https://circleci.com/gh/VisionSystemsInc/docker_recipes.svg?style=svg)](https://circleci.com/gh/VisionSystemsInc/docker_recipes)

A docker recipe is a (usually very small) docker image that is included in a multi-stage build so that you don't always have to find and repeat that "prefect set of Dockerfile lines to include software XYZ", such as gosu, tini, etc... They are based heavily on ONBUILD and meant to be used as their own stage.

## Example

```Dockerfile
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:gosu as gosu
FROM debian:9 #My real docker image

RUN echo stuff

COPY --from=tini /usr/local/bin/tini /usr/local/bin/tini
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
```

## How to use

When using all the defaults, the recipes can be used directly from dockerhub. However, when one of the recipes needs to customized via a build arg, it is often best to include this repo as a submodule in the greater project, and building from the dockerfiles.

## What this is not

A universal way to "INCLUDE" or "IMPORT" one Dockerfile into another. It only works under a certain set of circumstances

- Your file recipe output can be *easily* added using the Dockerfile `ADD` command
- You are ok with customizing the version number using build args to override the default value
- When your code is relatively portable. A python virtualenv is not, unfortunately. Go is almost always ultra portable.
    - musl versions have to be done separately. For example: tini (glibc) and tini-musl (musl)

## VSI Common

|Name|VSI Common|
|--|--|
|Output files|`/vsi/*`|

Some VSI Common functions are needed in the container, this provides a mechanism to copy them in, even if the `just` executable is used.

### Example

```Dockerfile
FROM vsiri/recipe:vsi as vsi
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=vsi /vsi /vsi
```

## tini

|Name|tini|
|--|--|
|Build Args|`TINI_VERSION` - Version of tini to download|
|Output files|`/usr/local/bin/tini`|

Tini is a process reaper, and should be used in dockers that spawn new processes

There is a similar version for alpine: tini-musl

### Example

```Dockerfile
FROM vsiri/recipe:tini as tini
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=tini /usr/local/bin/tini /usr/local/bin/tini
```

## gosu

|Name|gosu|
|--|--|
|Build Args|`GOSU_VERSION` - Version of gosu to download|
|Output files|`/usr/local/bin/gosu`|

sudo written with docker automation in mind (no passwords ever)

### Example

```Dockerfile
FROM vsiri/recipe:gosu as gosu
# The following line will NOT work. docker bug?
# RUN chmod u+s /usr/local/bin/gosu

FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
# Optionally add SUID bit so an unprivileged user can run as root (like sudo)
RUN chmod u+s /usr/local/bin/gosu
```

## ep - envplate

|Name|ep|
|--|--|
|Build Args|`EP_VERSION` - Version of ep to download|
|Output files|`/usr/local/bin/ep`|

ep is a simple way to apply bourne shell style variable name substitution to any generic configuration file for applications that do not support environment variable name substitution

### Example

```Dockerfile
FROM vsiri/recipe:ep as ep
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=ep /usr/local/bin/ep /usr/local/bin/ep
```

## jq - JSON Processor

|Name|jq|
|--|--|
|Build Args|`JQ_VERSION` - Version of jq to download|
|Output files|`/usr/local/bin/jq`|

jq is a lightweight and flexible command-line JSON processor

### Example

```Dockerfile
FROM vsiri/recipe:jq as jq
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=jq /usr/local/bin/jq /usr/local/bin/jq
```

## ninja

|Name|ninja|
|--|--|
|Build Args|`NINJA_VERSION` - Version of Ninja to download|
|Output files|`/usr/local/bin/ninja`|

Ninja is generally a better/faster alternative to GNU Make.


### Example

```Dockerfile
FROM vsiri/recipe:ninja as ninja
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=ninja /usr/local/bin/ninja /usr/local/bin/ninja
```

## Docker compose

|Name|Docker compose|
|--|--|
|Build Args|`DOCKER_COMPOSE_VERSION` - Version of docker-compose to download|
|Output dirs|`/usr/local/bin/docker-compose`|

Docker-compose is a tool for defining and running multi-container Docker applications

### Example

```Dockerfile
FROM vsiri/recipe:docker-compose as docker-compose
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose
```

## git Large File Support

|Name|git lfs|
|--|--|
|Build Args|`GIT_LFS_VERSION` - Version of git-lfs to download|
|Output dirs|`/usr/local/bin/git-lfs`|

git-lfs gives git the ability to handle large files gracefully.

```Dockerfile
FROM vsiri/recipe:git-lfs as git-lfs
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=git-lfs /usr/local/bin/git-lfs /usr/local/bin/git-lfs
```

## CMake

|Name|CMake|
|--|--|
|Build Args|`CMAKE_VERSION` - Version of CMake to download|
|Output files|`/cmake/*`|

CMake is a cross-platform family of tools designed to build, test and package software

### Example

```Dockerfile
FROM vsiri/recipe:cmake as cmake
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=cmake /cmake /usr/local/
```

## Pipenv

|Name|Pipenv|
|--|--|
|Build Args|`PIPENV_VERSION` - Version of pipenv source to download|
|Build Args|`PIPENV_VIRTUALENV` - The location of the pipenv virtualenv|
|Build Args|`PYTHON` - Optional default python exectuable to use
|Output dirs|`/tmp/pipenv/*`|

Pipenv is the new way to manage python requirements (within a virtualenv) on project.

Since this is setting up a virtualenv, you can't just move `/usr/local/pipenv` to anywhere in the destination image, it must created in the correct location. If this needs to be changed, adjust the `PIPENV_VIRTUALENV` arg.

The default python  will be used when `get-pipenv` is called. The default python is used for all other pipenv calls. In order to customize the default python interpreter used, set the `PYTHON` build arg, or else you will need to use the `--python/--two/--three` flags when calling `pipenv`

This recipe is a little different from other recipes in that it's just a script to set up the virtualenv in the destination image. Virtualenvs have to be done this way due to their non-portable nature; this is especially true because this virtualenv creates other virtutalenvs that need to point to the system python.

### Example

```Dockerfile
FROM vsiri/recipe:pipenv as pipenv
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=pipenv /tmp/pipenv /tmp/pipenv
RUN /tmp/pipenv/get-pipenv; rm -rf /tmp/pipenv || :
```

*Note*: `rm -f` and `|| :` handles cases like [this](https://github.com/moby/moby/issues/27358)

## Amanda debian packages

|Name|Amanda|
|--|--|
|Build Args|`AMANDA_VERSION` - Branch name to build off of (can be a SHA)|
|Output files|`/amanda-backup-client_${AMANDA_VERSION}-1Debian82_amd64.deb`<BR>`/amanda-backup-server_${AMANDA_VERSION}-1Debian82_amd64.deb`|

Complies Debian packages for the tape backup software Amanda

# J.U.S.T.

To define the "build recipes" target, add this to your `Justfile`

    source "${VSI_COMMON_DIR}/linux/just_docker_functions.bsh"

And add `justify build recipes` to any Justfile target that is responsible for building docker images.
