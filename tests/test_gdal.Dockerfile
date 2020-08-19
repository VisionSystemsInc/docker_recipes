FROM vsiri/recipe:gdal as gdal

FROM python:3
SHELL ["/usr/bin/env", "bash", "-euxvc"]

COPY --from=gdal /usr/local /usr/local
RUN ldconfig

RUN pip install numpy ; \
    pip install GDAL==$(cat /usr/local/gdal_version) ;
