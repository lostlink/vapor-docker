# syntax = edrevo/dockerfile-plus
FROM php:8.0-fpm

INCLUDE+ php80-debian.Dockerfile

RUN pecl channel-update pecl.php.net && \
    pecl install -o -f \
      swoole && \
    rm -rf /tmp/pear

RUN docker-php-ext-install \
      opcache && \
    docker-php-ext-enable \
      swoole
