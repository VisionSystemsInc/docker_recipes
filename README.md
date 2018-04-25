# Docker recipes

A docker recipe is a (usually very small) docker image that is included in a
multi-stage build so that you don't always have to find and repeat that "prefect
set of docker file lines to include software XYZ", such as gosu, tini, etc...
They are based heavily on ONBUILD and meant to be used as their own stage.

## Example

```Dockerfile
FROM vsiri/recipe:tini as tini
FROM vsiri/recipe:gosu as gosu
FROM debian:9 #My real docker image

RUN echo stuff

COPY --from=tini /usr/local/bin/tini /usr/local/bin/tini
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
```

## What this is not

A universal way to "INCLUDE" or "IMPORT" one dockerfile into another. It only
works under a certain set of circumstances

- Your file recipe output can be *easily* added using the Dockerfile `ADD` command
- You are ok with customizing version number using build args to override the
default vvalue

## tini

|Name|tini|
|--|--|
|Build Args|TINI_VERSION - Release name downloaded|
|Output files|/usr/local/bin/tini|

Tini is a process reaper, and should be used in docker that spawn new processes

There is a similar version for alpine: tini-aline

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
|Build Args|GOSU_VERSION - Release name downloaded|
|Output files|/usr/local/bin/gosu|

Sudo written with docker automation in mind (no passwords ever)

### Example

```Dockerfile
FROM vsiri/recipe:gosu as gosu
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
```

## ep - envplate

|Name|ep|
|--|--|
|Build Args|EP_VERSION - Release name downloaded|
|Output files|/usr/local/bin/ep|

ep is a simple way to apply bourne shell style variable name substitution on any generic configuration file for applications that do not support environment variable name substitution

## ninja

|Name|ninja|
|--|--|
|Build Args|NINJA_VERSION - Release name downloaded|
|Output files|/usr/local/bin/ninja|

Ninja is generally a better/faster alternative to GNU Make.

### Example

```Dockerfile
FROM vsiri/recipe:ep as ep
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=ep /usr/local/bin/ep /usr/local/bin/ep
```
## ninja

|Name|ninja|
|--|--|
|Build Args|NINJA_VERSION - Release name downloaded|
|Output files|/usr/local/bin/ninja|

Ninja is yet another build system, typically faster and simpler than make

### Example

```Dockerfile
FROM vsiri/recipe:ninja as ninja
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=ninja /usr/local/bin/ninja /usr/local/bin/ninja

## CMake

|Name|CMake|
|--|--|
|Build Args|CMAKE_VERSION - Version of cmake to download|
|Output files|/cmake/*|

CMake is a cross-platform family of tools designed to build, test and package software

### Example

```Dockerfile
FROM vsiri/recipe:cmake as cmake
FROM debian:9
RUN apt-get update; apt-get install vim
COPY --from=cmake /cmake/* /usr/local/
```

## Amanda debian packages

|Name|Amanda|
|--|--|
|Build Args|AMANDA_VERSION - Branch name to build off of (can be a sha)|
|Output files|/amanda-backup-client_${AMANDA_VERSION}-1Debian82_amd64.deb<BR>/amanda-backup-server_${AMANDA_VERSION}-1Debian82_amd64.deb|

Complies debian packages for the tape backup software Amanda

# J.U.S.T.

To define the "build recipes" target, add this to your `Justfile`

    source "${VSI_COMMON_DIR}/linux/just_docker_functions.bsh"

And add `(justify build recipes)` to any Justfile target that is responsible for buildling docker images.
