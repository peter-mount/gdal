# Dockerfile to build GDAL as a docker image
#

ARG ARCH=amd64
ARG VERSION=2.2.2

# ======================================================================
# Setup build environment
# ======================================================================
FROM ${ARCH}/alpine as gcc

RUN apk add --no-cache \
        curl \
        make \
        gcc \
        g++ \
        python \
        linux-headers \
        paxctl \
        libgcc \
        libstdc++

# ======================================================================
# Download sources
# ======================================================================
FROM gcc as download
ARG VERSION

RUN curl -s \
      http://download.osgeo.org/gdal/${VERSION}/gdal-${VERSION}.tar.gz \
      -o /tmp/gdal.tar.gz

# ======================================================================
# Build gdal
# ======================================================================
FROM download as compile
ARG VERSION

RUN cd /tmp &&\
    tar xvzpf gdal.tar.gz &&\
    mv gdal-${VERSION} gdal-src

RUN cd /tmp/gdal-src &&\
    ./configure --prefix=/usr/local/gdal

RUN cd /tmp/gdal-src &&\
    make

RUN cd /tmp/gdal-src &&\
    make install

# ======================================================================
# Build the gdal image
# ======================================================================
FROM ${ARCH}/alpine as gdal
LABEL maintainer="Peter Mount <peter@retep.org>"

# Required libraries
RUN apk add --no-cache \
      libgcc \
      libstdc++

# Install gdal
COPY --from=compile /usr/local/gdal /usr/local/gdal/

# symlink binaries into /usr/local/bin
RUN for i in /usr/local/gdal/bin/*; \
    do \
      ln -s $i /usr/local/bin/$(basename $i);\
    done
