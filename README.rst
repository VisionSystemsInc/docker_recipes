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

   RUN echo stuff

   COPY --from=tini /usr/local /usr/local
   COPY --from=gosu /usr/local /usr/local

How to use
==========

When using all the defaults, the recipes can be used directly from dockerhub. However, when one of the recipes needs to customized via a build arg, it is often best to include this repo as a submodule in the greater project, and building from the dockerfiles.

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
Output files ``/vsi/*``
============ ==========

Some VSI Common functions are needed in the container, this provides a mechanism to copy them in, even if the :file:`just` executable is used.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:vsi as vsi
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=vsi /vsi /vsi

tini
----

============ ====
Name         tini
Build Args   ``TINI_VERSION`` - Version of tini to download
Output files ``/usr/local/bin/tini`` and ``/usr/local/bin/_tini``
============ ====

Tini is a process reaper, and should be used in dockers that spawn new processes

There is a similar version for alpine: tini-musl

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:tini as tini
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=tini COPY /usr/local /usr/local

gosu
----

============ ====
Name         gosu
Build Args   ``GOSU_VERSION`` - Version of gosu to download
Output files ``/usr/local/bin/gosu``
============ ====

sudo written with docker automation in mind (no passwords ever)

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:gosu as gosu
   # The following line will NOT work. docker bug?
   # RUN chmod u+s /usr/local/bin/gosu

   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=gosu /usr/local/bin/gosu /usr/local/bin/gosu
   # Optionally add SUID bit so an unprivileged user can run as root (like sudo)
   RUN chmod u+s /usr/local/bin/gosu

ep - envplate
-------------

============ ==
Name         ep
Build Args   ``EP_VERSION`` - Version of ep to download
Output files ``/usr/local/bin/ep``
============ ==

ep is a simple way to apply bourne shell style variable name substitution to any generic configuration file for applications that do not support environment variable name substitution

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:ep as ep
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=ep /usr/local/bin/ep /usr/local/bin/ep

jq - JSON Processor
-------------------

============ ==
Name         jq
Build Args   ``JQ_VERSION`` - Version of jq to download
Output files ``/usr/local/bin/jq``
============ ==

jq is a lightweight and flexible command-line JSON processor

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:jq as jq
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=jq /usr/local/bin/jq /usr/local/bin/jq

ninja
-----

============ =====
Name         ninja
Build Args   ``NINJA_VERSION`` - Version of Ninja to download
Output files ``/usr/local/bin/ninja``
============ =====

Ninja is generally a better/faster alternative to GNU Make.


.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:ninja as ninja
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=ninja /usr/local/bin/ninja /usr/local/bin/ninja

Docker
------

=========== ==============
Name        Docker
Build Args  ``DOCKER_VERSION`` - Version of docker to download
Output dirs ``/usr/local/bin/`` including ``docker`` and several other files.
=========== ==============

Docker is a tool for running container applications

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:docker as docker
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=docker /usr/local /usr/local

Docker compose
--------------

This isn't actually a recipe, as the docker community already creates the images we need

For glibc, use ``docker/compose:${DOCKER_COMPOSE_VERSION}-debian``, and for musl (as of docker-compose version 1.25.0) use ``docker/compose:${DOCKER_COMPOSE_VERSION}-alpine``
.. rubric:: Example

.. code-block:: Dockerfile

   ARG ${DOCKER_COMPOSE_VERSION}
   FROM docker/compose:${DOCKER_COMPOSE_VERSION}-alpine as docker-compose
   FROM alpine:3.9
   RUN apk add --no-cache git
   COPY --from=docker-compose /usr/local/bin/docker-compose /usr/local/bin/docker-compose

As long as you don't use alpine 3.8 or older, this will work. In that case, you should probably install the glibc libraries and use the debian ``docker-compose`` in alpine.

git Large File Support
----------------------

=========== =======
Name        git lfs
Build Args  ``GIT_LFS_VERSION`` - Version of git-lfs to download
Output dirs ``/usr/local/bin/git-lfs``
=========== =======

git-lfs gives git the ability to handle large files gracefully.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:git-lfs as git-lfs
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=git-lfs /usr/local/bin/git-lfs /usr/local/bin/git-lfs

CMake
-----

============ =====
Name         CMake
Build Args   ``CMAKE_VERSION`` - Version of CMake to download
Output files ``/cmake/*``
============ =====

CMake is a cross-platform family of tools designed to build, test and package software

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:cmake as cmake
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=cmake /cmake /usr/local/

Pipenv
------

=========== ======
Name        Pipenv
Build Args  ``PIPENV_VERSION`` - Version of pipenv source to download
Build Args  ``PIPENV_VIRTUALENV`` - The location of the pipenv virtualenv
Build Args  ``PYTHON`` - Optional default python executable to us
Output dirs ``/tmp/pipenv/*``
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
   RUN apt-get update; apt-get install vim
   COPY --from=pipenv /tmp/pipenv /tmp/pipenv
   RUN /tmp/pipenv/get-pipenv; rm -rf /tmp/pipenv || :

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
Output files ``/use/local/bin/awk``
============ ============

https://github.com/onetrueawk/awk is a severly limited version awk that some primative operating systems use. This recipe will help in testing against that version.

.. rubric:: Example

.. code-block:: Dockerfile

   FROM vsiri/recipe:onetrueawk as onetrueawk
   FROM debian:9
   RUN apt-get update; apt-get install vim
   COPY --from=onetrueawk /usr/local/bin/awk /usr/local/bin/

J.U.S.T.
========

To define the "build recipes" target, add this to your ``Justfile``

.. code-block:: bash

   source "${VSI_COMMON_DIR}/linux/just_docker_functions.bsh"

And add ``justify build recipes`` to any Justfile target that is responsible for building docker images.
