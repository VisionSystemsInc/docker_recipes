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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=docker /usr/local /usr/local

Docker compose
--------------

=========== =======
Name        docker compose
Build Args  ``DOCKER_COMPOSE_VERSION`` - Version of docker-compose to download
Output dir  ``/usr/local``
=========== =======

Tool for running simple docker orchestratioon, giving an organized way to run one or more dockers.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:docker-compose as docker-compose
   FROM debian:9
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=docker-compose /usr/local /usr/local

This recipe will work glibc and musl for verion 2.0.0 and newer. Version 1 would need to use docker-compose provided images for alpine: ``docker/compose:alpine-${DOCKER_COMPOSE_VERSION}``

.. rubric:: Example

.. code-block:: Dockerfile

   ARG ${DOCKER_COMPOSE_VERSION-1.26.2}
   FROM docker/compose:alpine-${DOCKER_COMPOSE_VERSION} as docker-compose
   FROM alpine:3.11
   RUN apk add --no-cache git  # This line is just an example
   COPY --from=docker-compose /usr/local /usr/local

git Large File Support
----------------------

=========== =======
Name        git lfs
Build Args  ``GIT_LFS_VERSION`` - Version of git-lfs to download
Output dir  ``/usr/local``
=========== =======

git-lfs gives git the ability to handle large files gracefully.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:git-lfs as git-lfs
   FROM debian:9
   RUN apt-get update; apt-get install -y vim  # This line is just an example
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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=cmake /usr/local /usr/local

Pipenv
------

=========== ======
Name        Pipenv
Env Var     ``PIPENV_VERSION`` - Version of pipenv source to download
Env Var     ``PIPENV_VIRTUALENV`` - The location of the pipenv virtualenv
Env Var     ``PIPENV_PYTHON`` - Optional default python executable to use. This is useful when combined with the "Conda's Python" recipe
Output dir  ``/usr/local``
=========== ======

Pipenv is the new way to manage python requirements (within a virtualenv) on project.

Since this is setting up a virtualenv, you can't just move ``/usr/local/pipenv`` to anywhere in the destination image, it must created in the correct location. If this needs to be changed, adjust the ``PIPENV_VIRTUALENV`` arg.

The default python will be used when :ref:`get_pipenv` is called. The default python is used for all other pipenv calls. In order to customize the default python interpreter used, set the ``PYTHON`` build arg, or else you will need to use the ``--python/--two/--three`` flags when calling ``pipenv``.

This recipe is a little different from other recipes in that it's just a script to set up the virtualenv in the destination image. Virtualenvs have to be done this way due to their non-portable nature; this is especially true because this virtualenv creates other virtutalenvs that need to point to the system python.

A script called ``fake_package`` is added to the pipenv virtualenv, this script is useful for creating fake editable packages, that will be mounted in at run time.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:pipenv as pipenv
   FROM debian:9
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=pipenv /usr/local /usr/local
   ...
   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

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
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=onetrueawk /usr/local /usr/local

GDAL
----

============ ============
Name         GDAL
Build Args   ``GDAL_VERSION`` - Version of GDAL to download
Output dir   ``/usr/local``
============ ============

Compiles GDAL v3, including OPENJPEG 2.4, ECW J2K 5.5, libtiff4.3, libgeotiff 1.7, PROJ v8

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:gdal as gdal
   FROM python:3.8
   COPY --from=gdal /usr/local /usr/local

   # numpy must be installed before GDAL python bindings
   RUN pip install numpy; \
       pip install GDAL==$(cat /usr/local/gdal_version);

   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

PDAL
----

============ ============
Name         PDAL
Build Args   ``PDAL_VERSION`` - Version of PDAL to download
Output dir   ``/usr/local``
============ ============

Compiles PDAL v2 and dependencies.  Requires GDAL recipe install.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:gdal as gdal
   FROM vsiri/recipe:pdal as pdal
   FROM python:3.8
   COPY --from=gdal /usr/local /usr/local
   COPY --from=pdal /usr/local /usr/local

   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

Conda's python
--------------

============ ============
Name         Python
Build Args   ``PYTHON_VERSION`` - Version of python to download
Output dir   ``/usr/local``
============ ============

This is not a recipe for installing anaconda or miniconda, rather it internally uses miniconda to install a "not" conda python. This python will still bare the markings of Anaconda, but does not have all the conda modifications, and works as a normal and extremely portable version of python for glibc linux.

See https://anaconda.org/anaconda/python/files for values of ``PYTHON_VERSION``

This is the easiest way to install an arbitrary version of python on an arbitrary linux distro.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:conda-python as python
   FROM ubuntu:16.04
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=python /usr/local /usr/local


J.U.S.T.
========

To define the "build recipes" target, add this to your ``Justfile``

.. code-block:: bash

   source "${VSI_COMMON_DIR}/linux/just_files/just_docker_functions.bsh"

And add ``justify build recipes`` to any Justfile target that is responsible for building docker images.


