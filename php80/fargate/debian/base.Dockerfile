FROM php:8.0-fpm

RUN apt update && \
    apt upgrade -y && \
    apt install -y \
      nmap \
      wget \
      curl \
      supervisor \
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
      xsl \
      exif && \
    docker-php-ext-configure gd --with-freetype=/usr/lib/ --with-jpeg=/usr/lib/ && \
    docker-php-ext-install gd && \
    docker-php-ext-enable redis

RUN wget -O /opt/cert.pem http://curl.haxx.se/ca/cacert.pem

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && /
    php -r "if (hash_file('sha384', 'composer-setup.php') === '906a84df04cea2aa72f40b5f787e49f22d4c2f19492ac310e8cba5b96ac8b64115ac402c8cd292b8a03482574915d1a8') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" && /
    php composer-setup.php && /
    php -r "unlink('composer-setup.php');" && /
    mv composer.phar /usr/bin/composer

ARG WWWUSER=1000
ARG WWWGROUP=1000

WORKDIR /var/www/html

RUN groupadd --force -g $WWWGROUP octane && \
    useradd -ms /bin/bash --no-user-group -g $WWWGROUP -u 1337 octane && \
    if [ ! -z "$WWWUSER" ]; then \
        usermod -u $WWWUSER octane; \
    fi

COPY php80/fargate/deployment/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY php80/fargate/deployment/config/php.ini /usr/local/etc/php/php.ini
COPY php80/fargate/deployment/config/opcache.ini /usr/local/etc/php/conf.d/opcache.ini
COPY --chmod=755 php80/fargate/deployment/config/entrypoint.sh /entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
