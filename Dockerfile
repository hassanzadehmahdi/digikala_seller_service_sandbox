FROM php:8.2-apache

RUN echo "ServerName SellerServiceSandbox" >> /etc/apache2/apache2.conf

RUN apt-get update \
    && apt-get install -qq -y --no-install-recommends \
    cron \
    vim \
    locales \
    coreutils \
    apt-utils \
    git \
    unzip \
    libicu-dev \
    g++ \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    libxslt-dev \
    zlib1g-dev \
    libsasl2-dev \
    libssl-dev \
    librdkafka-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*


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


# APCU
RUN pecl install apcu && \
    docker-php-ext-enable apcu


# Redis
RUN pecl install redis && \
    docker-php-ext-enable redis


# AMQP
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions amqp


# Apache config
COPY ./Docker/worker/vhosts /etc/apache2/sites-enabled


# Application
COPY . /var/www

WORKDIR /var/www


# Install PHP dependencies
RUN composer install \
    --no-interaction \
    --prefer-dist \
    --optimize-autoloader


# Prepare SQLite storage
RUN mkdir -p var && \
    touch var/data.db && \
    chmod -R 777 var


# Startup script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh


ENTRYPOINT ["docker-entrypoint.sh"]
