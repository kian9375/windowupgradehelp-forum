FROM php:8.1-apache

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

# Fix MPM module conflict - disable event, enable prefork
RUN a2dismod mpm_event && a2enmod mpm_prefork

# Enable Apache modules
RUN a2enmod rewrite headers

# Configure PHP for phpBB
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY php.ini /usr/local/etc/php/conf.d/phpbb.ini

# Set working directory
WORKDIR /var/www/html

# Copy phpBB files
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/cache \
    && chmod -R 777 /var/www/html/files \
    && chmod -R 777 /var/www/html/store \
    && chmod -R 777 /var/www/html/images/avatars/upload \
    && chmod 660 /var/www/html/config.php

# Configure Apache
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Create startup script to handle dynamic PORT
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
