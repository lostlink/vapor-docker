FROM php:8.1-fpm

RUN pecl channel-update pecl.php.net && \
    pecl install -o -f \
      swoole && \
    rm -rf /tmp/pear

RUN docker-php-ext-enable \
      swoole
