FROM debian:9

RUN apt-get update &&\
    apt-get install -y \
      curl \
      dans-gdal-scripts \
      gdal-bin &&\
    apt-get clean
