FROM alpine:latest
LABEL maintainer "DI GREGORIO Nicolas <nicolas.digregorio@gmail.com>"
LABEL maintainer "Sawn <sawn01@gmail.com>"

### Environment variables
ENV LANG='en_US.UTF-8' \
    LANGUAGE='en_US.UTF-8' \
    TERM='xterm' \
    PYCURL_SSL_LIBRARY='openssl'

### Install Application
RUN apk --no-cache upgrade && \
    apk add --no-cache --virtual=build-deps \
      make \
      gcc \
      g++ \
      python3-dev \
      py3-pip \
      libressl-dev \
      curl-dev \
      musl-dev \
      libffi-dev \
      jpeg-dev \
      git \
      zlib-dev \
      py3-openssl
      py3-crypto 
      py3-pillow 
      py3-feedparser 
      py3-jinja2 
      py3-curl 
      tesseract-ocr && \
    pip --no-cache-dir install --upgrade setuptools && \
    pip --no-cache-dir install --upgrade \
      spidermonkey \
      tesseract-ocr \
      BeautifulSoup \
      thrift \
      beaker && \
    git clone --depth 1 https://github.com/pyload/pyload.git -b stable /opt/pyload && \
    apk del --no-cache --purge \
      build-deps  && \
    apk add --no-cache --virtual=run-deps \
      python3 \
      ssmtp \
      mailx \
      libffi \
      libcurl \
      jpeg \
      unrar-free \
      unzip \
      p7zip \
      zlib \
      su-exec && \
    rm -rf /tmp/* \
           /opt/pyload/.git \
           /var/cache/apk/*  \
           /var/tmp/*


### Volume
VOLUME ["/downloads","/config"]

### Expose ports
EXPOSE 8000 7227 9666

### Running User: not used, managed by docker-entrypoint.sh
#USER pyload

### Start pyload
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["pyload"]

