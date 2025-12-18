FROM php:8.1-apache-bookworm

# Force cache bust - v2
ARG CACHEBUST=2

# Install PHP extensions required by phpBB
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    mysqli \
    pdo_mysql \
    zip \
    intl \
    opcache \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Fix MPM module conflict - explicitly disable all then enable prefork only
RUN a2dismod mpm_event mpm_worker || true && a2enmod mpm_prefork

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure PHP for phpBB
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php.ini /usr/local/etc/php/conf.d/phpbb.ini

# Set working directory
WORKDIR /var/www/html

# Copy phpBB files
COPY --chown=www-data:www-data . /var/www/html/

# Set permissions
RUN chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/cache \
    && chmod -R 777 /var/www/html/files \
    && chmod -R 777 /var/www/html/store \
    && chmod -R 777 /var/www/html/images/avatars/upload \
    && chmod 660 /var/www/html/config.php

# Configure Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create startup script to handle dynamic PORT
RUN echo '#!/bin/bash\n\
PORT=${PORT:-80}\n\
sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf\n\
sed -i "s/<VirtualHost \\*:80>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-available/000-default.conf\n\
exec apache2-foreground' > /start.sh && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
