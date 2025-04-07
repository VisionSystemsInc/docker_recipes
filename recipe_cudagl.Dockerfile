# syntax=docker/dockerfile:1.4

FROM scratch as scripts

COPY --chmod=755 <<EOF /setup
set -euxv
mkdir /opt/libglvnd
cd /opt/libglvnd
# Clone
git clone --branch="\${LIBGLVND_VERSION}" https://github.com/NVIDIA/libglvnd.git .
# Build/install
./autogen.sh
./configure --prefix=/usr/local --libdir=/usr/local/lib64
make -j"$(nproc)" install-strip
find /usr/local/lib64 -type f -name 'lib*.la' -delete
# do it all over again for 32 bit
make distclean
./autogen.sh
./configure --prefix=/usr/local --libdir=/usr/local/lib --host=i386-linux-gnu "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32"
make -j"$(nproc)" install-strip
find /usr/local/lib -type f -name 'lib*.la' -delete
EOF

FROM redhat/ubi8 as ubi8

SHELL ["/usr/bin/env", "bash", "-euxvc"]

ADD --chmod=755 10_sideload_rocky /usr/local/share/just/scripts/

RUN /usr/local/share/just/scripts/10_sideload_rocky; \
    dnf install -y --enablerepo=rocky-appstream,rocky-powertools \
                   git make libtool gcc pkgconfig python2 libXext-devel \
                   libX11-devel xorg-x11-proto-devel\
                   glibc-devel.i686 libgcc.i686 libXext-devel.i686 libX11-devel.i686; \
    rm -rf /var/cache/yum/*

ARG LIBGLVND_VERSION=v1.2.0
COPY --from=scripts /setup /setup
RUN /setup

FROM redhat/ubi9 as ubi9

SHELL ["/usr/bin/env", "bash", "-euxvc"]

ADD --chmod=755 10_sideload_rocky /usr/local/share/just/scripts/

RUN /usr/local/share/just/scripts/10_sideload_rocky; \
    dnf install -y --enablerepo=rocky-appstream,rocky-crb \
                   git make libtool gcc pkgconfig libXext-devel \
                   libX11-devel xorg-x11-proto-devel\
                   glibc-devel.i686 libgcc.i686 libXext-devel.i686 libX11-devel.i686; \
    rm -rf /var/cache/yum/*

ARG LIBGLVND_VERSION=v1.2.0
COPY --from=scripts /setup /setup
RUN /setup

FROM alpine:3.11.8

SHELL ["/usr/bin/env", "sh", "-euxvc"]

COPY --from=ubi8 /usr/local/lib /usr/local/share/just/info/rhel8/lib
COPY --from=ubi8 /usr/local/lib64 /usr/local/share/just/info/rhel8/lib64

COPY --from=ubi9 /usr/local/lib /usr/local/share/just/info/rhel9/lib
COPY --from=ubi9 /usr/local/lib64 /usr/local/share/just/info/rhel9/lib64

ADD --chmod=644 10_load_cuda_env /usr/local/share/just/user_run_patch/
ADD --chmod=755 30_ldconfig 40_install_cudagl /usr/local/share/just/container_build_patch/
ADD --chmod=755 10_sideload_rocky /usr/local/share/just/scripts/

COPY <<EOF /usr/local/share/glvnd/egl_vendor.d/10_nvidia.json
{
    "file_format_version" : "1.0.0",
    "ICD" : {
        "library_path" : "libEGL_nvidia.so.0"
    }
}
EOF

ONBUILD ARG CUDA_RECIPE_TARGET=runtime

ONBUILD RUN case "${CUDA_RECIPE_TARGET}" in *devel*) \
              apk add --no-cache --virtual .del git; \
              # Headers part 1
              git clone https://github.com/KhronosGroup/OpenGL-Registry.git; \
              cd OpenGL-Registry; \
                git checkout 681c365c012ac9d3bcadd67de10af4730eb460e0; \
                cp -r api/GL /usr/local/include; \
              cd ..; \
              # Headers part 2
              git clone https://github.com/KhronosGroup/EGL-Registry.git; \
              cd EGL-Registry; \
                git checkout 0fa0d37da846998aa838ed2b784a340c28dadff3; \
                cp -r api/EGL api/KHR /usr/local/include; \
              cd ..; \
              # Headers part 3
              git clone --branch=mesa-17.3.3 --depth=1 https://gitlab.freedesktop.org/mesa/mesa.git; \
              cd mesa; \
                mkdir /usr/local/include/GL; \
                cp include/GL/gl.h include/GL/gl_mangle.h /usr/local/include/GL/; \
              cd ..; \
              # cleanup
              apk del .del; \
              mkdir /usr/local/share/just/info/cuda/; \
              echo 'PKG_CONFIG_PATH=${PKG_CONFIG_PATH-}${PKG_CONFIG_PATH:+:}/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig' > /usr/local/share/just/info/cuda/30_pkgconfig_rhel; \
              ;; \
            esac

ONBUILD ARG LIBGLVND_VERSION=v1.2.0

ONBUILD COPY <<EOF /usr/local/share/just/info/cuda/00_cudagl_common
: \${CUDA_RECIPE_TARGET:=${CUDA_RECIPE_TARGET}}
: \${LIBGLVND_VERSION:=${LIBGLVND_VERSION}}
EOF
