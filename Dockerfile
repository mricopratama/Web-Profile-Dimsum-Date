# Menggunakan base image PHP 8.2 CLI
FROM php:8.2-cli

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

# Salin file-file dependensi terlebih dahulu untuk optimasi cache Docker
COPY composer.json composer.lock ./
COPY package.json package-lock.json* ./

# Jalankan 'composer update' untuk menyesuaikan dependensi dengan versi PHP 8.2
# Ini akan membuat ulang composer.lock dengan versi paket yang kompatibel.
# CATATAN: Praktik terbaik adalah menjalankan 'composer update' di lingkungan
# pengembangan lokal Anda dan commit file composer.lock yang baru.
RUN composer update --no-interaction --no-dev --optimize-autoloader

# Install dependensi NPM
RUN npm install --legacy-peer-deps

# Salin sisa file aplikasi ke dalam direktori kerja
# File yang sudah ada seperti composer.json tidak akan terpengaruh secara signifikan
COPY . .

# Build aset frontend
RUN npm run build

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

# Perintah untuk menjalankan server Octane saat kontainer dijalankan
# Menggunakan format exec untuk praktik terbaik
CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=8000"]
