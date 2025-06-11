FROM composer:2 as composer_stage
WORKDIR /app
COPY database/ database/
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --prefer-dist --ignore-platform-reqs

FROM node:18-alpine as node_stage
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM php:8.3-cli

RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    libpq-dev \
    nodejs \
    npm \
    && docker-php-ext-install -j$(nproc) pcntl bcmath pdo pdo_pgsql zip intl sockets \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN composer install --no-interaction --no-dev --optimize-autoloader

RUN npm install --legacy-peer-deps && npm run build

RUN php artisan octane:install --server=roadrunner --no-interaction

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

EXPOSE 8000

CMD ["php", "artisan", "octane:start", "--host=0.0.0.0", "--port=8000"]
