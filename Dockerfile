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

RUN cd /tmp/gdal-src/swig/python &&\
    python setup.py build

RUN cd /tmp/gdal-src/swig/python &&\
    export packagedir=/usr/local/gdal/lib/python$(python --version 2>&1 |cut -f2 -d' ')/site-packages &&\
    mkdir -p $packagedir &&\
    PYTHONPATH=$packagedir setup.py install --prefix=/usr/local/gdal &&\
    PYTHONPATH=$packagedir:$PYTHONPATH python -c "from osgeo import gdal; print(gdal.__version__)"

# ======================================================================
# Build the gdal image
# ======================================================================
FROM ${ARCH}/alpine as gdal
LABEL maintainer="Peter Mount <peter@retep.org>"

# Required libraries
RUN apk add --no-cache \
      libgcc \
      libstdc++ \
      python

# Install gdal
COPY --from=compile /usr/local/gdal /usr/local/gdal/

# symlink binaries into /usr/local/bin
RUN for i in /usr/local/gdal/bin/*; \
    do \
      ln -s $i /usr/local/bin/$(basename $i);\
    done

# ======================================================================
# Build the gdal/node image
# ======================================================================
FROM area51/${ARCH}-node as node
LABEL maintainer="Peter Mount <peter@retep.org>"

# Additional tools
RUN apk add --no-cache \
      imagemagick

# Install gdal
COPY --from=compile /usr/local/gdal /usr/local/gdal/

# symlink binaries into /usr/local/bin
RUN for i in /usr/local/gdal/bin/*; \
    do \
      ln -s $i /usr/local/bin/$(basename $i);\
    done
