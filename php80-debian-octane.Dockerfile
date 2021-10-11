FROM lostlink/vapor:php80-debian

RUN pecl channel-update pecl.php.net && \
    pecl install -o -f \
      swoole && \
    rm -rf /tmp/pear

RUN docker-php-ext-install \
      opcache && \
    docker-php-ext-enable \
      swoole
