FROM php:7.3-apache

ENV MEMCACHED_HOST "127.0.0.1"
ENV MEMCACHED_PORT "11211"
ENV MEMCACHED_USERNAME "admin"
ENV MEMCACHED_PASSWORD "pass"
ENV APP_DIR "/var/www/html"
ENV APACHE_DOCUMENT_ROOT "$APP_DIR/web"
ENV DEBIAN_FRONTEND noninteractive

RUN mkdir -p $APACHE_DOCUMENT_ROOT

# configure dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    git

# configure apache
RUN sed -ri -e '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    # use the PORT environment variable in Apache configuration files.
    && sed -i 's/80/${PORT}/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# configure PHP – https://github.com/php/php-src/blob/master/php.ini-production
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# install required php extensions:
# curl, xml, and mbstring already installed
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
# basic extensions:
RUN install-php-extensions zip

WORKDIR $APP_DIR

COPY . .

# configure app
RUN mv app/.config.dist app/.config \
    && chown -R root:root "${APP_DIR}"

# install composer:
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN composer install
