FROM php:8.2-fpm-bookworm

ARG UID=1001
ARG GID=1001

RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    zip \
    vim \
    cron \
    nginx \
    default-mysql-client \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libsodium-dev \
    libmagickwand-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        bcmath \
        ctype \
        curl \
        dom \
        gd \
        intl \
        mbstring \
        mysqli \
        pdo_mysql \
        soap \
        sockets \
        sodium \
        xsl \
        zip \
        opcache \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN groupadd -g ${GID} clp && \
    useradd -u ${UID} -g clp -m -s /bin/bash test-ssh

WORKDIR /var/www/html

RUN chown -R test-ssh:clp /var/www/html

USER test-ssh
