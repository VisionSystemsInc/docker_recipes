# CentOS 6 with GDAL 3+
# - includes OPENJPEG 2.4, ECW J2K 5.5, libtiff4.3, libgeotiff 1.7, PROJ v8
# - compatible with pypi GDAL bindings (recipe does not build python bindings)
# - recipe is not currently compatible with GDAL 2.
#
# This dockerfile follows procedures from the offical GDAL dockers
#   https://github.com/OSGeo/gdal/tree/master/gdal/docker
#
# This dockerfile is derived from the manylinux2010 base image, derived from
# CentOS 6 and already containing many updated build essentials.
#   https://github.com/pypa/manylinux
#
# In the future, the manylinux2010 image could enable a portable GDAL that
# includes internal copies of necessary dependencies and python bindings
# for a selected python version. This recipe currently does not build any
# python bindings.
#
# As this base image includes build essentials already in /usr/local,
# libraries are staged in "/gdal/usr/local".  The last build step clears
# /usr/local of other packages, then migrates the staging directory to
# /usr/local for consistency with other recipes.
#
#
# -----------------------------------------------------------------------------
# EXAMPLE USAGE
# -----------------------------------------------------------------------------
# FROM vsiri/recipe:gdal as gdal
# FROM python:3.8
# COPY --from=gdal /usr/local /usr/local
#
# # numpy must be installed before GDAL python bindings
# RUN pip install numpy; \
#     pip install GDAL==$(cat /usr/local/gdal_version);
#
# # Only needs to be run once for all recipes
# RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done

# -----------------------------------------------------------------------------
# BASE IMAGE
# -----------------------------------------------------------------------------

# base image
FROM quay.io/pypa/manylinux2014_x86_64:2022-02-13-594988e as base_image

# Set shell to bash
SHELL ["/usr/bin/env", "/bin/bash", "-euxvc"]


# -----------------------------------------------------------------------------
# OPENJPEG v2
# -----------------------------------------------------------------------------
FROM base_image as openjpeg

# variables
ENV OPENJPEG_VERSION=2.4.0
ENV STAGING_DIR=/openjpeg

# install
RUN TEMP_DIR="/tmp${STAGING_DIR}"; \
    REPORT_DIR="${STAGING_DIR}/usr/local/recipe"; \
    mkdir -p "${TEMP_DIR}" "${REPORT_DIR}"; \
    cd "${TEMP_DIR}"; \
    #
    # download & unzip
    TAR_FILE="v${OPENJPEG_VERSION}.tar.gz"; \
    curl -fsSLO "https://github.com/uclouvain/openjpeg/archive/${TAR_FILE}"; \
    tar -xvf "${TAR_FILE}" --strip-components=1; \
    #
    # configure, build, & install
    cmake . \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=OFF \
        -DCMAKE_BUILD_TYPE=Release; \
    make -j"$(nproc)"; \
    make install DESTDIR="${STAGING_DIR}"; \
    echo "${OPENJPEG_VERSION}" > "${REPORT_DIR}/openjpeg_version"; \
    #
    # cleanup
    rm -rf "${TEMP_DIR}";


# -----------------------------------------------------------------------------
# ECW v5
# -----------------------------------------------------------------------------
FROM base_image as ecw

# variables
ENV ECW_VERSION=5.5.0
ENV STAGING_DIR=/ecw

# install
RUN TEMP_DIR="/tmp${STAGING_DIR}"; \
    REPORT_DIR="${STAGING_DIR}/usr/local/recipe"; \
    mkdir -p "${TEMP_DIR}" "${REPORT_DIR}"; \
    cd "${TEMP_DIR}"; \
    #
    # local variables
    if [ "${ECW_VERSION}" == "5.4.0" ]; then \
      ZIP_FILE=ERDASECWJP2SDKv54Update1forLinux; \
      UNPACK_DIR=/hexagon/ERDAS-ECW_JPEG_2000_SDK-5.4.0/Desktop_Read-Only; \
    elif [ "${ECW_VERSION}" == "5.5.0" ]; then \
      ZIP_FILE=erdas-ecw-jp2-sdk-v55-update-1-linux; \
      UNPACK_DIR=/root/hexagon/ERDAS-ECW_JPEG_2000_SDK-5.5.0/Desktop_Read-Only; \
    else \
      echo "Unrecognized ECW version ${ECW_VERSION}"; \
      exit 1; \
    fi; \
    #
    # download & unzip
    curl -fsSLO "https://go.hexagongeospatial.com/${ZIP_FILE}"; \
    unzip "${ZIP_FILE}"; \
    #
    # unpack & cleanup
    printf '1\nyes\n' | MORE=-V bash ./*.bin; \
    #
    # copy necessary files
    # this removes the "new ABI" .so files as they are note needed
    LOCAL_DIR="${STAGING_DIR}/usr/local/ecw"; \
    mkdir -p "${LOCAL_DIR}"; \
    cp -r "${UNPACK_DIR}"/{*.txt,bin,etc,include,lib,third*} "${LOCAL_DIR}"; \
    echo "${ECW_VERSION}" > "${REPORT_DIR}/ecw_version"; \
    #
    # remove the "new C++11 ABI"
    rm -rf "${LOCAL_DIR}"/{lib/cpp11abi,lib/newabi} \
           "${LOCAL_DIR}"/{lib/x64/debug,bin/x64/debug}; \
    #
    # cleanup
    rm -r "${TEMP_DIR}" "${UNPACK_DIR}";

# link .so files to "/usr/local/lib" for easier discovery
RUN mkdir -p "${STAGING_DIR}/usr/local/lib"; \
    cd "${STAGING_DIR}/usr/local/lib"; \
    ln -s ../ecw/lib/x64/release/libNCSEcw.so* .;


# -----------------------------------------------------------------------------
# LIBTIFF
# -----------------------------------------------------------------------------
# https://gitlab.com/libtiff/libtiff
FROM base_image as tiff

# variables
ENV TIFF_VERSION=4.3.0
ENV STAGING_DIR=/tiff

# additional build dependencies
RUN yum install -y \
      libjpeg-turbo-devel \
      zlib-devel; \
    yum clean all

# install
RUN TEMP_DIR="/tmp${STAGING_DIR}"; \
    REPORT_DIR="${STAGING_DIR}/usr/local/recipe"; \
    mkdir -p "${TEMP_DIR}" "${REPORT_DIR}"; \
    cd "${TEMP_DIR}"; \
    #
    # download & unzip
    TAR_FILE="tiff-${TIFF_VERSION}.tar.gz"; \
    curl -fsSLO "https://download.osgeo.org/libtiff/${TAR_FILE}"; \
    tar -xf "${TAR_FILE}" --strip-components=1; \
    #
    # configure, build, & install
    ./configure \
        --disable-static \
        | tee "${REPORT_DIR}/tiff_configure"; \
    make -j"$(nproc)"; \
    make install DESTDIR="${STAGING_DIR}"; \
    echo "$TIFF_VERSION" > "${REPORT_DIR}/tiff_version"; \
    #
    # cleanup
    rm -r "${TEMP_DIR}";


# -----------------------------------------------------------------------------
# PROJ v6
# -----------------------------------------------------------------------------
# install instructions: https://proj.org/install.html
FROM base_image as proj

# variables
ENV PROJ_VERSION=8.1.1
ENV STAGING_DIR=/proj

# additional build dependencies
RUN yum install -y \
      libcurl-devel \
      libjpeg-turbo-devel \
      zlib-devel; \
    yum clean all

# local dependencies to staging directory
COPY --from=tiff /tiff/usr/local /usr/local

# install
RUN TEMP_DIR="/tmp${STAGING_DIR}"; \
    REPORT_DIR="${STAGING_DIR}/usr/local/recipe"; \
    mkdir -p "${TEMP_DIR}" "${REPORT_DIR}"; \
    cd "${TEMP_DIR}"; \
    #
    # download & unzip
    TAR_FILE="proj-${PROJ_VERSION}.tar.gz"; \
    curl -fsSLO "https://download.osgeo.org/proj/${TAR_FILE}"; \
    tar -xf ${TAR_FILE} --strip-components=1; \
    #
    # configure, build, & install
    ./configure \
        CFLAGS='-DPROJ_RENAME_SYMBOLS -O2' \
        CXXFLAGS='-DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -O2' \
        --disable-static \
        | tee "${REPORT_DIR}/proj_configure"; \
    make -j"$(nproc)"; \
    make install "DESTDIR=${STAGING_DIR}"; \
    echo "${PROJ_VERSION}" > "${REPORT_DIR}/proj_version"; \
    #
    # cleanup
    rm -r "${TEMP_DIR}";


# -----------------------------------------------------------------------------
# GEOTIFF
# -----------------------------------------------------------------------------
# https://github.com/OSGeo/libgeotiff
FROM base_image as geotiff

# variables
ENV GEOTIFF_VERSION=1.7.0
ENV STAGING_DIR=/geotiff

# additional build dependencies
RUN yum install -y \
      libcurl-devel \
      libjpeg-turbo-devel \
      zlib-devel; \
    yum clean all

# local dependencies to staging directory
COPY --from=tiff /tiff/usr/local /usr/local
COPY --from=proj /proj/usr/local /usr/local

# install
RUN TEMP_DIR="/tmp${STAGING_DIR}"; \
    REPORT_DIR="${STAGING_DIR}/usr/local/recipe"; \
    mkdir -p "${TEMP_DIR}" "${REPORT_DIR}"; \
    cd "${TEMP_DIR}"; \
    mkdir -p "./source" "./build"; \
    #
    # download & unzip
    TAR_FILE="libgeotiff-${GEOTIFF_VERSION}.tar.gz"; \
    curl -fsSLO "https://download.osgeo.org/geotiff/libgeotiff/${TAR_FILE}"; \
    tar -xf "${TAR_FILE}" --strip-components=1; \
    #
    # configure, build, & install
    ./configure \
        --with-jpeg \
        --with-proj=/usr/local \
        --with-zlib \
        | tee "${REPORT_DIR}/geotiff_configure"; \
    make -j"$(nproc)"; \
    make install DESTDIR="${STAGING_DIR}"; \
    echo "$GEOTIFF_VERSION" > "${REPORT_DIR}/geotiff_version"; \
    #
    # cleanup
    rm -r "${TEMP_DIR}";


# -----------------------------------------------------------------------------
# GDAL (final image)
# -----------------------------------------------------------------------------
FROM base_image

# variables
ENV STAGING_DIR=/gdal

# additional build dependencies
RUN yum install -y \
      libcurl-devel \
      libjpeg-turbo-devel \
      zlib-devel; \
    yum clean all

# local dependencies to staging directory
# the base_image has many other dependencies already in /usr/local,
# so we isolate packages in a staging directory
COPY --from=openjpeg /openjpeg ${STAGING_DIR}
COPY --from=ecw /ecw ${STAGING_DIR}
COPY --from=tiff /tiff ${STAGING_DIR}
COPY --from=proj /proj ${STAGING_DIR}
COPY --from=geotiff /geotiff ${STAGING_DIR}

# local dependencies to /usr/local
# This is necessary only for those dependencies expected to be in a "normal"
# location. GDAL "configure" accepts direct paths for many packages, including
# ECW and PROJ.
COPY --from=openjpeg /openjpeg/usr/local /usr/local

# add staged libraries
ENV LD_LIBRARY_PATH="${STAGING_DIR}/usr/local/lib"

# Patch file for downstream image
ENV GDAL_PATCH_FILE=${STAGING_DIR}/usr/local/share/just/container_build_patch/30_gdal
ADD 30_gdal ${GDAL_PATCH_FILE}
RUN chmod +x ${GDAL_PATCH_FILE}

# install
ONBUILD ARG GDAL_VERSION=3.3.3

ONBUILD RUN \
    TEMP_DIR="/tmp${STAGING_DIR}"; \
    REPORT_DIR="${STAGING_DIR}/usr/local/recipe"; \
    mkdir -p "${TEMP_DIR}" "${REPORT_DIR}"; \
    cd "${TEMP_DIR}"; \
    #
    # download & unzip
    TAR_FILE="gdal-${GDAL_VERSION}.tar.gz"; \
    curl -fsSLO "https://download.osgeo.org/gdal/${GDAL_VERSION}/${TAR_FILE}"; \
    tar -xf "${TAR_FILE}" --strip-components=1; \
    #
    # configure, build, & install
    # https://raw.githubusercontent.com/OSGeo/gdal/master/gdal/configure
    ./configure \
        --without-libtool \
        --with-hide-internal-symbols \
        --with-jpeg=internal \
        --with-png=internal \
        --with-pcre=no \
        --with-libtiff="${STAGING_DIR}/usr/local" \
        --with-geotiff="${STAGING_DIR}/usr/local" \
        --with-openjpeg \
        --with-proj="${STAGING_DIR}/usr/local" \
        --with-ecw="${STAGING_DIR}/usr/local/ecw" \
        | tee "${REPORT_DIR}/gdal_configure"; \
    # cat "${TEMP_DIR}/config.log"; \
    #
    # build & install
    make -j "$(nproc)"; \
    make install "DESTDIR=${STAGING_DIR}"; \
    echo "${GDAL_VERSION}" > "${REPORT_DIR}/gdal_version"; \
    #
    # cleanup
    rm -r "${TEMP_DIR}";

# migrate staging directory to /usr/local
ONBUILD RUN rm -rf /usr/local; \
            mv "${STAGING_DIR}/usr/local" /usr/local
