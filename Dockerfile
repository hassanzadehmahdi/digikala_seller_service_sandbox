FROM php:8.2-apache

RUN echo "ServerName SellerServiceSandbox" >> /etc/apache2/apache2.conf


# System dependencies
RUN apt-get update \
    && apt-get install -qq -y --no-install-recommends \
    locales \
    git \
    unzip \
    curl \
    libicu-dev \
    g++ \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libxslt-dev \
    zlib1g-dev \
    libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*


# Locales
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "fa_IR.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen


# Install Composer
RUN curl -sSk https://getcomposer.org/installer | php -- --disable-tls && \
    mv composer.phar /usr/local/bin/composer


# PHP extensions
RUN docker-php-ext-configure intl

RUN docker-php-ext-install \
    pdo \
    pdo_sqlite \
    pdo_mysql \
    mysqli \
    gd \
    opcache \
    intl \
    zip \
    calendar \
    dom \
    mbstring \
    xsl \
    && a2enmod rewrite


# Apache virtual host
COPY ./Docker/worker/vhosts /etc/apache2/sites-enabled


# Application
COPY . /var/www

WORKDIR /var/www


# Install PHP dependencies
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader


# Prepare SQLite database
RUN mkdir -p var && \
    touch var/data.db && \
    chmod -R 777 var


# Startup script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh


ENTRYPOINT ["docker-entrypoint.sh"]
