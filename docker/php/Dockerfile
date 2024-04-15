FROM php:8.2-fpm

ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer

# バージョン指定をしないと2.7より前の脆弱性があるバージョンをインストールしてしまうため指定している（そのうち要らなくなるはず）
COPY --from=composer:2.7 /usr/bin/composer /usr/bin/composer

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        git \
        zip \
        unzip \
        vim \
        libicu-dev \
        libonig-dev \
        libzip-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-install \
        intl \
        pdo_mysql \
        mbstring \
        zip \
        bcmath
