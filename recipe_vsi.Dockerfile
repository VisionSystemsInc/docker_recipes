FROM alpine:3.11

COPY . /vsi

# Unfortunately pyinstaller changed everything to 700
RUN chmod -R 777 /vsi/Justfile /vsi/env* /vsi/linux