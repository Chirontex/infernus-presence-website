# Build stage
FROM php:8.4-fpm-alpine AS builder

ARG PHP_VERSION=8.4

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libjpeg-turbo-dev \
    libfreetype6-dev \
    zip \
    unzip \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo \
        pdo_mysql \
        opcache \
        intl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy composer files
COPY composer.json composer.lock ./

# Install PHP dependencies
RUN composer install \
    --no-interaction \
    --no-dev \
    --optimize-autoloader \
    --prefer-dist

# Production stage
FROM php:8.4-fpm-alpine

ARG PHP_VERSION=8.4

# Install runtime dependencies
RUN apk add --no-cache \
    mysql-client \
    libpng \
    libjpeg-turbo \
    libfreetype6 \
    curl \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo \
        pdo_mysql \
        opcache \
        intl

# Configure PHP
COPY docker/php.ini /usr/local/etc/php/conf.d/app.ini
COPY docker/www.conf /usr/local/etc/php-fpm.d/www.conf

# Create app user
RUN addgroup -g 1000 app && adduser -D -u 1000 -G app app

# Set working directory
WORKDIR /app

# Copy application code
COPY . .

# Copy vendor from builder
COPY --from=builder /app/vendor /app/vendor

# Fix permissions
RUN chown -R app:app /app

# Switch to app user
USER app

# Expose PHP-FPM port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=10s \
    CMD curl -f http://localhost:9000/ping || exit 1

CMD ["php-fpm"]
