FROM vsiri/recipe:gdal as gdal
FROM vsiri/recipe:pdal as pdal
FROM python:3.8
SHELL ["/usr/bin/env", "bash", "-euxvc"]

# copy from recipes
COPY --from=gdal /usr/local /usr/local
COPY --from=pdal /usr/local /usr/local

# install pdal python bindings
# note PDAL python bindings are versioned separately from PDAL
# PDAL is built in in a manylinux container using the old C++ ABI.
# Ensure the pdal python wheel is built from source using the same ABI.
RUN CXXFLAGS="-D_GLIBCXX_USE_CXX11_ABI=0" pip install PDAL

# Only needs to be run once for all recipes
RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
