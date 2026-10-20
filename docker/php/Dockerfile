FROM php:8.4-fpm

ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip \
    && rm -rf /var/lib/apt/lists/* \
    && install-php-extensions pdo_mysql mysqli zip intl bcmath gd exif pcntl opcache

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY local.ini /usr/local/etc/php/conf.d/zz-local.ini

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_PROCESS_TIMEOUT=0

WORKDIR /var/www/html
