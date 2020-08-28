==============
Docker recipes
==============

.. image:: https://circleci.com/gh/VisionSystemsInc/docker_recipes.svg?style=svg
   :target: https://circleci.com/gh/VisionSystemsInc/docker_recipes
   :alt: CirclCI

A docker recipe is a (usually very small) docker image that is included in a multi-stage build so that you don't always have to find and repeat that "prefect set of Dockerfile lines to include software XYZ", such as gosu, tini, etc... They are based heavily on ONBUILD and meant to be used as their own stage.

.. rubric:: Example

.. code-block:: Dockerfile

   Dockerfile
   FROM vsiri/recipe:tini as tini
   FROM vsiri/recipe:gosu as gosu
   FROM debian:9 #My real docker image

   RUN echo stuff  # This line is just an example

   COPY --from=tini /usr/local /usr/local
   COPY --from=gosu /usr/local /usr/local

   # Universal patch command that all recipes could use
   RUN shopt -s nullglob; for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

How to use
==========

The recipes can be used directly from dockerhub. It is also possible to include this repo as a submodule in the greater project, and building directly from the dockerfiles.

Many recipes have build arguments. This allows you to control what versions (usually) the recipe will use. This means the build arg needs to be set when the docker build command is issued, unless you want to use the default value.

* When using ``docker``, this is done by ``docker build --build-arg key=val ...``.

* With ``docker-compose`` this can be done by ``docker-compose build --build-arg key=val ...``.

  * But it is usually better to add it to the ``docker-compose.yml`` file.

* What you cannot do is add a build ``ARG`` to the global section of the ``Dockerfile`` and expect that default value to affect the recipe, that is not how they work.

What this is not
================

A universal way to "INCLUDE" or "IMPORT" one Dockerfile into another. It only works under a certain set of circumstances

* Your file recipe output can be *easily* added using the Dockerfile ``ADD`` command

* You are ok with customizing the version number using build args to override the default value

* When your code is relatively portable. A python virtualenv is not, unfortunately. Go (when compiled statically) is almost always ultra portable.

  * musl versions have to be done separately. For example: tini (glibc) and tini-musl (musl)

Recipes
=======

VSI Common
----------

============ ==========
Name         VSI Common
Output dir   ``/vsi``
============ ==========

Some VSI Common functions are needed in the container, this provides a mechanism to copy them in, even if the :file:`just` executable is used.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:vsi as vsi
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=vsi /vsi /vsi

tini
----

============ ====
Name         tini
Build Args   ``TINI_VERSION`` - Version of tini to download
Output dir   ``/usr/local``
============ ====

Tini is a process reaper, and should be used in dockers that spawn new processes

There is a similar version for alpine: tini-musl

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:tini as tini
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=tini COPY /usr/local /usr/local

gosu
----

============ ====
Name         gosu
Build Args   ``GOSU_VERSION`` - Version of gosu to download
Output dir   ``/usr/local``
============ ====

sudo written with docker automation in mind (no passwords ever)

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:gosu as gosu
   # The following line will NOT work. docker bug?
   # RUN chmod u+s /usr/local/bin/gosu

   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=gosu /usr/local /usr/local
   # Optionally add SUID bit so an unprivileged user can run as root (like sudo)
   RUN chmod u+s /usr/local/bin/gosu

ep - envplate
-------------

============ ==
Name         ep
Build Args   ``EP_VERSION`` - Version of ep to download
Output dir   ``/usr/local``
============ ==

ep is a simple way to apply bourne shell style variable name substitution to any generic configuration file for applications that do not support environment variable name substitution

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:ep as ep
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=ep /usr/local /usr/local

jq - JSON Processor
-------------------

============ ==
Name         jq
Build Args   ``JQ_VERSION`` - Version of jq to download
Output dir   ``/usr/local``
============ ==

jq is a lightweight and flexible command-line JSON processor

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:jq as jq
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=jq /usr/local /usr/local

ninja
-----

============ =====
Name         ninja
Build Args   ``NINJA_VERSION`` - Version of Ninja to download
Output dir   ``/usr/local``
============ =====

Ninja is generally a better/faster alternative to GNU Make.


.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:ninja as ninja
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=ninja /usr/local /usr/local

Docker
------

=========== ==============
Name        Docker
Build Args  ``DOCKER_VERSION`` - Version of docker to download
Output dir  ``/usr/local`` including ``docker`` and several other files.
=========== ==============

Docker is a tool for running container applications

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:docker as docker
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=docker /usr/local /usr/local

Docker compose
--------------

Docker compose doesn't actually need a recipe, as the docker community already creates the images we need

As of version 1.25.2, for glibc, use ``docker/compose:debian-${DOCKER_COMPOSE_VERSION}``, and for musl use ``docker/compose:alpine-${DOCKER_COMPOSE_VERSION}``

.. rubric:: Example

.. code-block:: Dockerfile

   ARG ${DOCKER_COMPOSE_VERSION-1.26.2}
   FROM docker/compose:alpine-${DOCKER_COMPOSE_VERSION} as docker-compose
   FROM alpine:3.11
   RUN apk add --no-cache git  # This line is just an example
   COPY --from=docker-compose /usr/local /usr/local

.. note::

   This recipe does have you use the ``ARG`` command in your ``Dockerfile``

As long as you don't use alpine 3.8 or older, this will work. If you are using alpine 3.8 or older, you should probably install the glibc libraries and use the debian ``docker-compose`` in alpine.

.. rubric:: Recipe

If you need a recipe that you can use if the base image is allowed to switch between musl and glibc, it requires a few extra lines than a normal recipe.

.. rubric:: Example

.. code-block:: Dockerfile

   ARG ${DOCKER_COMPOSE_VERSION}
   FROM docker/compose:alpine-${DOCKER_COMPOSE_VERSION} as docker-compose_musl
   FROM docker/compose:debian-${DOCKER_COMPOSE_VERSION} as docker-compose_glib
   FROM vsiri/recipe:docker-compose as docker-compose
   FROM alpine:3.11
   ...
   COPY --from=docker-compose_musl /usr/local/bin/docker-compose /usr/local/bin/docker-compose_musl
   COPY --from=docker-compose_glib /usr/local/bin/docker-compose /usr/local/bin/docker-compose_glib
   COPY --from=docker-compose /usr/local /usr/local

A script attempts to auto-detect musl vs glibc. If this script is unable to come to the correct decision, set ``VSI_MUSL`` to ``1`` to force musl or ``0`` for glibc

git Large File Support
----------------------

=========== =======
Name        git lfs
Build Args  ``GIT_LFS_VERSION`` - Version of git-lfs to download
Output dir  ``/usr/local/bin/git-lfs``
=========== =======

git-lfs gives git the ability to handle large files gracefully.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:git-lfs as git-lfs
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=git-lfs /usr/local /usr/local
   ...
   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

CMake
-----

============ =====
Name         CMake
Build Args   ``CMAKE_VERSION`` - Version of CMake to download
Output dir   ``/usr/local``
============ =====

CMake is a cross-platform family of tools designed to build, test and package software

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:cmake as cmake
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=cmake /usr/local /usr/local

Pipenv
------

=========== ======
Name        Pipenv
Build Args  ``PIPENV_VERSION`` - Version of pipenv source to download
Build Args  ``PIPENV_VIRTUALENV`` - The location of the pipenv virtualenv
Build Args  ``PIPENV_PYTHON`` - Optional default python executable to use. This is useful when combined with the "Conda's Python" recipe
Output dir  ``/usr/local``
=========== ======

Pipenv is the new way to manage python requirements (within a virtualenv) on project.

Since this is setting up a virtualenv, you can't just move ``/usr/local/pipenv`` to anywhere in the destination image, it must created in the correct location. If this needs to be changed, adjust the ``PIPENV_VIRTUALENV`` arg.

The default python  will be used when :ref:`get_pipenv` is called. The default python is used for all other pipenv calls. In order to customize the default python interpreter used, set the ``PYTHON`` build arg, or else you will need to use the ``--python/--two/--three`` flags when calling ``pipenv``

This recipe is a little different from other recipes in that it's just a script to set up the virtualenv in the destination image. Virtualenvs have to be done this way due to their non-portable nature; this is especially true because this virtualenv creates other virtutalenvs that need to point to the system python.

A script called ``fake_package`` is added to the pipenv virtualenv, this script is useful for creating fake editable packages, that will be mounted in at run time.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:pipenv as pipenv
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=pipenv /usr/local /usr/local
   ...
   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

.. note::

   ``rm -f`` and ``|| :`` handles cases like `this <https://github.com/moby/moby/issues/27358>`_

Amanda debian packages
----------------------

============ ======
Name         Amanda
Build Args   ``AMANDA_VERSION`` - Branch name to build off of (can be a SHA)
Output files * ``/amanda-backup-client_${AMANDA_VERSION}-1Debian82_amd64.deb``
             * ``/amanda-backup-server{AMANDA_VERSION}-1Debian82_amd64.deb``
============ ======

Complies Debian packages for the tape backup software Amanda

One True Awk
------------

============ ============
Name         One True Awk
Build Args   ``ONETRUEAWK_VERSION`` - Version of one true awk to download
Output dir   ``/usr/local``
============ ============

https://github.com/onetrueawk/awk is a severly limited version awk that some primative operating systems use. This recipe will help in testing against that version.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:onetrueawk as onetrueawk
   FROM debian:9
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=onetrueawk /usr/local /usr/local

GDAL
----

============ ============
Name         GDAL
Build Args   ``GDAL_VERSION`` - Version of GDAL to download
Output dir   ``/usr/local``
============ ============

Compiles GDAL v3, including PROJ v6, ECW J2K 5.5, OPENJPEG 2.3

.. rubric:: Example

.. code-block:: Dockerfile

   FROM python:3.6.9-slim-jessie as python
   FROM vsiri/recipe:gdal as gdal
   FROM ubuntu:16.04

   # set shell to bash
   SHELL ["/usr/bin/env", "/bin/bash", "-euxvc"]

   # install python & gdal
   COPY --from=python /usr/local /usr/local/
   COPY --from=gdal /usr/local /usr/local

   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

   # additional dependencies
   RUN apt-get update -y; \
      DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
         expat libffi6 libssl1.0.0 libtiff5 sqlite3 ; \
      rm -rf /var/lib/apt/lists/* ;

   # install numpy (before pypi GDAL bindings)
   RUN pip3 install numpy ;

   # pypi GDAL bindings
   RUN export BUILD_DEPS="g++" ; \
      apt-get update -y ; \
      DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends \
         ${BUILD_DEPS} ; \
      pip3 install GDAL==$(cat /usr/local/gdal_version) ; \
      apt-get clean ${BUILD_DEPS} ; \
      rm -rf /var/lib/apt/lists/* ;

   CMD ["gdalinfo", "--version"]

Conda's python
--------------

============ ============
Name         Python
Build Args   ``PYTHON_VERSION`` - Version of python to download
Output dir   ``/usr/local``
============ ============

This is not a recipe for installing anaconda or miniconda, rather it internally uses miniconda to install a "not" conda python. This python will still bare the markings of Anaconda, but does not have all the conda modifications, and works as a normal and extremely portable version of python for glibc linux.

This is the easiest way to install an arbitrary version of python on an arbitrary linux distro.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:conda-python as python
   FROM ubuntu:16.04
   RUN apt-get update; apt-get install vim  # This line is just an example
   COPY --from=python /usr/local /usr/local


J.U.S.T.
========

To define the "build recipes" target, add this to your ``Justfile``

.. code-block:: bash

   source "${VSI_COMMON_DIR}/linux/just_files/just_docker_functions.bsh"

And add ``justify build recipes`` to any Justfile target that is responsible for building docker images.


