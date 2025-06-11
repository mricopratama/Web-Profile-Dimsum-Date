FROM php:8.3-cli

RUN apt-get update && apt-get install -y \
    git curl unzip libzip-dev libonig-dev libicu-dev libpq-dev nodejs npm \
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

RUN curl -Ls https://github.com/roadrunner-server/roadrunner/releases/latest/download/roadrunner-linux-amd64.tar.gz \
    | tar -xz -C /usr/local/bin && chmod +x /usr/local/bin/rr

RUN chown -R www-data:www-data /var/www/html

USER www-data

EXPOSE 8000

RUN php artisan config:clear && php artisan cache:clear

CMD php artisan octane:start --server=roadrunner --host=0.0.0.0 --port=8000
