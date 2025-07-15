# backend/php-drupal/Dockerfile - FIXED VERSION
FROM php:8.1-apache

# Install required PHP extensions
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Copy the entire project first
COPY . /app/

# Set the correct document root to the web subdirectory
ENV APACHE_DOCUMENT_ROOT /app/web
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Set proper permissions
RUN chown -R www-data:www-data /app

# Enable Apache rewrite module for Drupal
RUN a2enmod rewrite

EXPOSE 80