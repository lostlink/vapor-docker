FROM php:8.0-fpm

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
      nmap \
      wget \
      curl \
      ca-certificates \
      libmcrypt-dev \
      libxml2-dev \
      libpcre3-dev \
      zlib1g-dev \
      autoconf \
      libonig-dev \
      openssl \
      libssl-dev \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libjpeg-dev \
      libpng-dev \
      libmagickwand-dev \
      libmagickcore-dev \
      imagemagick \
      libpq-dev \
      libzip-dev \
      gettext \
      libxslt-dev \
      libgcrypt-dev

RUN pecl channel-update pecl.php.net && \
    pecl install -o -f \
      redis-5.3.2 && \
    rm -rf /tmp/pear

RUN docker-php-ext-install \
      mysqli \
      mbstring \
      pdo \
      pdo_mysql \
      tokenizer \
      xml \
      pcntl \
      bcmath \
      pdo_pgsql \
      zip \
      intl \
      gettext \
      soap \
      sockets \
      xsl

RUN docker-php-ext-configure gd --with-freetype=/usr/lib/ --with-jpeg=/usr/lib/ && \
    docker-php-ext-install gd

RUN docker-php-ext-enable \
      redis

RUN wget -O /opt/cert.pem http://curl.haxx.se/ca/cacert.pem

COPY php80/runtime/bootstrap /opt/bootstrap
COPY php80/runtime/bootstrap.php /opt/bootstrap.php
COPY php80/runtime/php.ini /usr/local/etc/php/php.ini

RUN chmod 755 /opt/bootstrap
RUN chmod 755 /opt/bootstrap.php

ENTRYPOINT []

CMD /opt/bootstrap
