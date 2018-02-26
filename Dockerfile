# Dockerfile to build GDAL as a docker image
#

ARG VERSION=2.2.3

# ======================================================================
# Setup build environment & download the sources
# ======================================================================
FROM area51/alpine-dev as download
ARG VERSION

RUN curl -s \
      http://download.osgeo.org/gdal/${VERSION}/gdal-${VERSION}.tar.gz \
      -o /tmp/gdal.tar.gz

RUN cd /tmp &&\
    tar xvzpf gdal.tar.gz &&\
    mv gdal-${VERSION} gdal-src

# ======================================================================
# Build gdal
# ======================================================================
FROM download as configure

RUN cd /tmp/gdal-src &&\
    ./configure --prefix=/usr/local/gdal

FROM configure as make
RUN cd /tmp/gdal-src &&\
    make

FROM make as install
RUN cd /tmp/gdal-src &&\
    make install

FROM install as dist
RUN mkdir -p /work/usr/local/bin &&\
    cp -rp /usr/local/gdal /work/usr/local/gdal &&\
    cd /work/user/local/bin &&\
    for i in ../gdal/bin/*; \
    do \
      ln -s $i $(basename $i);\
    done

# ======================================================================
# Build the gdal image
# ======================================================================
FROM alpine as gdal
LABEL maintainer="Peter Mount <peter@retep.org>"

# Required libraries
RUN apk add --no-cache \
      libgcc \
      libstdc++

# Install gdal
COPY --from=dist /work/usr/local /usr/local/
