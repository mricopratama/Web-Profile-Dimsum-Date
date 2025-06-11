# Menggunakan base image PHP 8.3 CLI
FROM php:8.3-cli

# Instalasi dependensi sistem, termasuk libbrotli-dev yang dibutuhkan oleh Swoole
# dan ekstensi PHP yang umum digunakan untuk Laravel.
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
    libbrotli-dev \
    && docker-php-ext-install -j$(nproc) pcntl bcmath pdo pdo_pgsql zip intl sockets \
    && pecl install swoole \
    && docker-php-ext-enable swoole \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Salin Composer dari image resmi Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Atur direktori kerja
WORKDIR /var/www/html

# Salin semua file aplikasi ke dalam direktori kerja
COPY . .

# Install dependensi Composer untuk produksi
RUN composer install --no-interaction --no-dev --optimize-autoloader

# Install dependensi NPM dan build aset frontend
RUN npm install --legacy-peer-deps && npm run build

# Install Laravel Octane dengan server Swoole
RUN php artisan octane:install --server=swoole --no-interaction

# Atur kepemilikan dan izin file/folder agar bisa ditulis oleh server
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

# Atur kepemilikan seluruh direktori aplikasi ke www-data
RUN chown -R www-data:www-data /var/www/html

# Ganti user ke www-data untuk menjalankan aplikasi
USER www-data

# Expose port yang akan digunakan oleh Octane
EXPOSE 8000

# Bersihkan cache config dan application cache sebagai langkah terakhir
RUN php artisan config:clear && php artisan cache:clear

# Perintah untuk menjalankan server Octane saat kontainer dijalankan
# Menggunakan format exec untuk praktik terbaik
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
