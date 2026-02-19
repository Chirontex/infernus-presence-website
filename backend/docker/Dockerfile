FROM php:8.4-fpm-alpine

ARG PHP_VERSION=8.4

# Install system and build dependencies
RUN apk add --no-cache \
    mysql-client \
    libpng \
    libjpeg-turbo \
    libfreetype6 \
    curl \
    git \
    zip \
    unzip \
    && apk add --no-cache --virtual .build-deps \
        libpng-dev \
        libjpeg-turbo-dev \
        libfreetype6-dev \
    && docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        pdo \
        pdo_mysql \
        opcache \
        intl \
    && apk del .build-deps

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure PHP
COPY docker/php.ini /usr/local/etc/php/conf.d/app.ini
COPY docker/www.conf /usr/local/etc/php-fpm.d/www.conf

# Create app user
RUN addgroup -g 1000 app && adduser -D -u 1000 -G app app

# Set working directory
WORKDIR /app

# Create vendor directory with proper permissions
RUN mkdir -p /app/vendor && chown -R app:app /app

# Switch to app user
USER app

# Expose PHP-FPM port
EXPOSE 9000

# Health check
HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=10s \
    CMD curl -f http://localhost:9000/ping || exit 1

CMD ["php-fpm"]
