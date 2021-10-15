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

RUN groupadd --force -g $WWWGROUP octane && \
    useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 octane && \
    if [ ! -z "$WWWUSER" ]; then \
        usermod -u $WWWUSER octane; \
    fi

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog

RUN cp php80/fargate/deployment/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf && \
    cp php80/fargate/deployment/config/php.ini /usr/local/etc/php/php.ini && \
    cp php80/fargate/deployment/config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini && \
    mkdir /var/www/html/octane/ && \
    cp php80/fargate/deployment/config/entrypoint.sh /var/www/html/octane/entrypoint.sh && \
    chgrp -R octane /var/www/html/storage/logs/ /var/www/html/bootstrap/cache/ && \
    chmod +x /var/www/html/octane/entrypoint.sh && \
	echo 'php(){ echo "Running php as octane user ..."; su octane -c "php $*";}' >> ~/.bashrc && \
	ln -s /var/www/html/deployment/octane/entrypoint.sh /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
