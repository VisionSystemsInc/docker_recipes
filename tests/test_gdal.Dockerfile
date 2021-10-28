FROM vsiri/recipe:gdal as gdal
FROM python:3.8
COPY --from=gdal /usr/local /usr/local

# numpy must be installed before GDAL python bindings
RUN pip install numpy ; \
    pip install GDAL==$(cat /usr/local/gdal_version) ;

# Only needs to be run once for all recipes
RUN for patch in /usr/local/share/just/container_build_patch/*; do "${patch}"; done
