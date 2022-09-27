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

Rocky Repos
-----------

=========== =================
Name        Rocky Linux Repos
Output dir  ``/usr/local``
=========== =================

Rocky Linux is a subscription free RHEL alternative. Often adding Rocky packages to a UBI image is useful.

Since this is installs specific packages based on the base image, you can't just move ``/usr/local/pipenv`` to anywhere in the destination image, it is a script that must run in the image.

This recipe is a little different from other recipes in that it's just a script to install repos (and corresponding gpg keys).

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:rocky as rocky
   FROM redhat/ubi8
   COPY --from=rocky /usr/local /usr/local
   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

   RUN dnf install -y --enablerepo=rocky-appstream telnet # This line is just an example
   ...

CUDA
----

=========================== ============
Name                        CUDA
Build Args                  ``CUDA_REPO_REF`` - The version of the CUDA container repo parsed
Build Args                  ``CUDA_VERSION`` - Version of CUDA to install (e.g. ``10.2`` or ``11.0.7``)
Build Args                  ``CUDNN_VERSION`` - Optional: Version of CUDNN to install. (e.g. ``7`` or ``8``)
Build Args                  ``CUDA_RECIPE_TARGET`` - Optional: Specifies how much of the CUDA stack to install (explained below). Default: ``runtime``
Environment Variable        ``NVIDIA_VISIBLE_DEVICES`` - Required: Sets which nvidia devices are visible in the container. Default: ``all``
Environment Variable        ``NVIDIA_DRIVER_CAPABILITIES`` - Optional: Which device capabilities are enabled in the container. Default: `compute,utility`, which is also the value the runtime interprets if this environment variable is unset.
Environment Variable        ``NVIDIA_REQUIRE_*`` - Optional: Sets test conditions to prevent running on incompatible systems
Output dir                  ``/usr/local``
Minimum Dockerfile frontend: docker/dockerfile:1.3-labs or docker/dockerfile:1.4
=======================================

While starting from a base image with CUDA already setup for docker is ideal, when we have to be based on a specific image (e.g. hardened images), this becomes impossible or impractical. Instead we need to start with a particular image and add CUDA support to it.

Currently, only RHEL and Ubuntu based images are supported (not Fedora or Debian).

There are many steps to setting up CUDA in an image:

- Setting up the CUDA repo and GPG key
- Installing the right packages, so that we limit the amount of bloat to the image
- Setting certain environment variables at container create time
- Setting various environment variables at container run time

This recipe will attempt to do all of these things in as few steps as possible, except setting environment variables at container create time which you will have to do manually.

---------------------
Environment variables
---------------------

Because of how the nvidia runtime operates, it needs certain variables set at container create time. Some ways this can be accomplished include:

- Adding an ``ENV`` to the Dockerfile
- Adding to the ``environment:`` section in ``docker-compose.yml``
- Adding the ``-e`` flag to the ``docker run`` call

``NVIDIA_VISIBLE_DEVICES`` must be set, or else the nvidia runtime will not activate, and you will have no GPU support. It's suggested to set ``NVIDIA_VISIBLE_DEVICES`` to ``all`` and allow for an environment variable on the host (i.e. in ``local.env``) to override the value to use specific GPUs as needed.

``NVIDIA_DRIVER_CAPABILITIES`` is usually set, but it is optional because unset and set to null means the ``compute,utility`` capabilities are passed in. This is enough for most CUDA capabilities.

You can optionally add ``NVIDIA_REQUIRE_*`` environment variables (Commonly: ``NVIDIA_REQUIRE_CUDA``) as a set of rules to declare what version of cuda, drivers, architecture, and brand. You only need to set this if you want docker to refuse to run when constraints are not met (e.g. driver doesn't support CUDA 11.6). See the `documentation <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html#constraints>`_ and an `example <https://gitlab.com/nvidia/container-images/cuda/-/blob/5bc8c5483115b8e9c68d4f1280acb8d56196d681/dist/11.6.2/ubi8/base/Dockerfile#L6>`_ for more information.

----------
Build Args
----------

The ``CUDA_VERSION``/``CUDNN_VERSION`` build args must be limited to the versions of CUDA in the `nvidia package repos <https://developer.download.nvidia.com/compute/cuda/repos/>`_. Attempting combinations of OS versions and CUDA versions not in the nvidia `codebase <https://gitlab.com/nvidia/container-images/cuda/-/tree/master/dist>`_ will probably fail because those versions of CUDA most likely do not exist in the nvidia package repos. Currently the end-of-life directory is not supported.

``CUDA_RECIPE_TARGET`` is used to specify how much of the CUDA stack to install (devel vs runtime):

- ``runtime``: Only installs the runtime packages for CUDA
- ``devel``: Installs both the runtime and development packages for CUDA
- ``devel-only``: Only installs the devel packages. This is intended to be used on an image that already has the CUDA runtime installed.

.. rubric:: Example

.. code-block:: Dockerfile

   # syntax=docker/dockerfile:1.4
   FROM vsiri/recipe:cuda as cuda

   FROM redhat/ubi8
   COPY --from=cuda /usr/local /usr/local
   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
   ENV NVIDIA_VISIBLE_DEVICES=all # Required for this recipe
   ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility # Optional: compute,utility is the default if unset

   # (Uncommon) If you need all the nvidia environment variables, source this file
   RUN source /usr/local/share/just/user_run_patch/10_load_cuda_env; \
       cmake # This line is just an example
   ...

CUDA GL
-------

=========================== ============
Name                        CUDA GL
Build Args                  ``CUDA_RECIPE_TARGET`` - Specifies how much of the CUDA stack to install (explained further above in the CUDA recipe). Default: ``runtime``
Build Args                  ``LIBGLVND_VERSION`` - The version of the GLVND used. Default: ``v1.2.0``
Environment Variable        ``NVIDIA_DRIVER_CAPABILITIES`` - For OpenGL offscreen rendering, you at least need `graphics,compute,utility`
Output dir                  ``/usr/local``
Minimum Dockerfile frontend: docker/dockerfile:1.3-labs or docker/dockerfile:1.4
=========================== ============

Similar to the CUDA recipe, ``CUDA_RECIPE_TARGET`` tells the recipe whether to install runtime or development dependencies, although ``devel-only`` installs both runtime and devel packages, due to how the recipe is structured.

``LIBGLVND_VERSION`` sets the version of `glvnd repo <https://github.com/NVIDIA/libglvnd.git>`_ that is compiled and used.

You will need to set the environment variable ``NVIDIA_DRIVER_CAPABILITIES`` to allow graphics capabilities which most GL applications will need.

.. rubric:: Example

.. code-block:: Dockerfile

   # syntax=docker/dockerfile:1.4
   FROM vsiri/recipe:cudagl as cudagl

   FROM redhat/ubi8
   COPY --from=cudagl /usr/local /usr/local
   # Only needs to be run once for all recipes
   RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

   ENV NVIDIA_DRIVER_CAPABILITIES=graphics,compute,utility
   ...

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


PROJ-data
---------

============ ============
Name         PROJ-data
Build Args   ``PROJ_DATA_VERSION`` - Version of proj-data to download
Output dir   ``/usr/local``
============ ============

This is a recipe for installing `PROJ-data <https://github.com/OSGeo/PROJ-data>`_, a very large (over 500MB) plugin for the `PROJ <https://github.com/OSGeo/PROJ>`_ package. PROJ-data contains a variety of datum grid files necessary for horizontal and vertical coordinate transformations.

PROJ-data files are fully optional, and only downloaded and installed ``PROJ_DATA_VERSION`` is set.

Users may alternatively make use of `remotely hosted PROJ-data <https://proj.org/usage/network.html>`_ to avoid installation of this large package.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:proj-data as proj-data
   FROM ubuntu:16.04
   RUN apt-get update; apt-get install -y vim  # This line is just an example
   COPY --from=proj-data /usr/local /usr/local


J.U.S.T.
========

To define the "build recipes" target, add this to your ``Justfile``

.. code-block:: bash

   source "${VSI_COMMON_DIR}/linux/just_files/just_docker_functions.bsh"

And add ``justify build recipes`` to any Justfile target that is responsible for building docker images.


