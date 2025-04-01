FROM php:8.3-fpm

ARG BUILD_ARGUMENT_ENV=dev
ENV ENV=$BUILD_ARGUMENT_ENV
ENV APP_HOME /var/www/html
ARG HOST_UID=1000
ARG HOST_GID=1000
ENV USERNAME=www-data

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    procps \
    nano \
    git \
    unzip \
    libicu-dev \
    zlib1g-dev \
    libxml2 \
    libxml2-dev \
    libreadline-dev \
    supervisor \
    cron \
    sudo \
    libzip-dev \
    wget \
    && docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
    && docker-php-ext-configure intl \
    && pecl install -o -f redis && docker-php-ext-enable redis \
    && docker-php-ext-install \
      pdo_mysql \
      sockets \
      intl \
      opcache \
      zip \
    && rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

RUN chown -R www-data:www-data /var/www/html

COPY ./docker/$BUILD_ARGUMENT_ENV/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./docker/$BUILD_ARGUMENT_ENV/php.ini /usr/local/etc/php/php.ini

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER 1

WORKDIR $APP_HOME

COPY --chown=${USERNAME}:${USERNAME} . $APP_HOME/

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --optimize-autoloader --no-interaction --no-progress \
    $(if [ "$BUILD_ARGUMENT_ENV" != "dev" ] && [ "$BUILD_ARGUMENT_ENV" != "test" ]; then echo "--no-dev"; fi)

RUN if [ "$BUILD_ARGUMENT_ENV" = "staging" ] || [ "$BUILD_ARGUMENT_ENV" = "prod" ]; then composer dump-autoload --optimize; \
    fi

USER root
