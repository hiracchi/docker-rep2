FROM ubuntu:18.04

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/hiracchi/docker-rep2" \
      org.label-schema.version=$VERSION \
      maintainer="Toshiyuki Hirano <hiracchi@gmail.com>"

ARG EXT=/ext

# -----------------------------------------------------------------------------
# JP
# -----------------------------------------------------------------------------
ENV LANG="ja_JP.UTF-8" LANGUAGE="ja_JP:en" LC_ALL="ja_JP.UTF-8" DEBIAN_FRONTEND="noninteractive" TZ="Asia/Tokyo"

RUN set -x \
  && apt-get update \
  && apt-get install -y \
     apt-utils sudo wget gnupg locales language-pack-ja tzdata \
  && apt-get update \
  && locale-gen ja_JP.UTF-8 \
  && update-locale LANG=ja_JP.UTF-8 \
  && apt-get install -y tzdata \
  && echo "${TZ}" > /etc/timezone \
  && mv /etc/localtime /etc/localtime.orig \
  && ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# rep2
# -----------------------------------------------------------------------------
RUN set -x \
  && apt-get update \
  && apt-get -y install --no-install-recommends \
    git curl patch \
    apache2 \
    php php-xml php-curl \
    php-mbstring php-sqlite3 \
    libapache2-mod-php \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN set -x \
  && mkdir -p ${EXT}

WORKDIR /usr/local
RUN set -x \
  && git clone "https://github.com/open774/p2-php.git"

ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_NO_INTERACTION 1

WORKDIR /usr/local/p2-php
RUN set -x \
  && curl -O "http://getcomposer.org/composer.phar" \
  && php -d detect_unicode=0 composer.phar install
RUN set -x \
  && chmod 0777 data/* rep2/ic \
  && chown -R www-data:www-data /usr/local/p2-php 
RUN set -x \
  && php scripts/p2cmd.php check

# -----------------------------------------------------------------------------
# 2ch proxy
# -----------------------------------------------------------------------------
RUN set -x \
  && apt-get update \
  && apt-get -y install --no-install-recommends \
    libhttp-daemon-perl liblwp-protocol-https-perl libyaml-tiny-perl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* 

WORKDIR /tmp
RUN set -x \
  && git clone "https://github.com/yama-natuki/2chproxy.pl.git" \
  && cp /tmp/2chproxy.pl/2chproxy.pl /usr/local/bin/2chproxy.pl \
  && rm -rf /tmp/2chproxy.pl
COPY 2chproxy.conf /usr/local/etc/2chproxy.conf

# -----------------------------------------------------------------------------
# directory setting
# -----------------------------------------------------------------------------
WORKDIR /usr/local/p2-php
RUN set -x \
  && ln -s /usr/local/p2-php/rep2 /var/www/html/rep2

# how to patch;
# diff -uprN conf.orig conf
COPY p2-php.patch /usr/local/p2-php/p2-php.patch
RUN set -x \
  && cp -r /usr/local/p2-php/conf /usr/local/p2-php/conf.orig \
  && patch -p1 -d conf < p2-php.patch

RUN set -x \
  && mkdir -p /usr/local/p2-php/.default \
  && mv /usr/local/p2-php/conf /usr/local/p2-php/.default/ \
  && ln -s ${EXT}/conf /usr/local/p2-php/conf \
  && mv /usr/local/p2-php/data /usr/local/p2-php/.default/ \
  && ln -s ${EXT}/data /usr/local/p2-php/data \
  && mv /usr/local/p2-php/rep2/ic /usr/local/p2-php/.default/ \
  && ln -s ${EXT}/ic /usr/local/p2-php/rep2/ic

# -----------------------------------------------------------------------------
# test
# -----------------------------------------------------------------------------
COPY phpinfo.php /var/www/html/phpinfo.php

# -----------------------------------------------------------------------------
# entrypoint
# -----------------------------------------------------------------------------
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY run-apache2.sh /usr/local/bin/run-apache2.sh
RUN chmod a+x /usr/local/bin/run-apache2.sh

VOLUME ${EXT}
EXPOSE 80
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/local/bin/run-apache2.sh"]
