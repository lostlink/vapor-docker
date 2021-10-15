FROM php:8.0-fpm-alpine

RUN apk --update add \
    wget \
    curl \
    build-base \
    supervisor \
    libmcrypt-dev \
    libxml2-dev \
    pcre-dev \
    zlib-dev \
    autoconf \
    oniguruma-dev \
    openssl \
    openssl-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    jpeg-dev \
    libpng-dev \
    imagemagick-dev \
    imagemagick \
    postgresql-dev \
    libzip-dev \
    gettext-dev \
    libxslt-dev \
    libgcrypt-dev &&\
  rm /var/cache/apk/*

RUN pecl channel-update pecl.php.net && \
    pecl install mcrypt redis-5.3.2 && \
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
      xsl && \
    docker-php-ext-configure gd --with-freetype=/usr/lib/ --with-jpeg=/usr/lib/ && \
    docker-php-ext-install gd && \
    docker-php-ext-enable redis

RUN wget -O /opt/cert.pem http://curl.haxx.se/ca/cacert.pem

ARG WWWUSER=1000
ARG WWWGROUP=1000

WORKDIR /var/www/html

RUN addgroup -g $WWWGROUP octane && \
    adduser -s /bin/bash -G octane -u $WWWUSER octane -D

COPY php80/fargate/deployment/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php80/fargate/deployment/config/php.ini /usr/local/etc/php/php.ini
COPY php80/fargate/deployment/config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY --chmod=755 php80/fargate/deployment/config/entrypoint.sh /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
