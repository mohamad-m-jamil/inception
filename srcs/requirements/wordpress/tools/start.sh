#!/bin/bash

# Read passwords from secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# Create directories only if they don't exist
mkdir -p /var/www/html
mkdir -p /run/php

cd /var/www/html

# Install WP-CLI only if not present
if [ ! -f /usr/local/bin/wp ]; then
    echo "Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Wait for MariaDB to be ready
until mysql -h mariadb -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for MariaDB to be ready..."
    sleep 3
done

# Only initialize WordPress if not already done
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "First run - setting up WordPress..."
    
    # Download WordPress
    wp core download --allow-root
    
    # Create wp-config.php
    wp config create --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass=$MYSQL_PASSWORD \
        --dbhost=mariadb:3306 \
        --allow-root
    
    # Install WordPress
    wp core install --url=https://$DOMAIN_NAME \
        --title="$WP_TITLE" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL \
        --skip-email \
        --allow-root
    
    # Create additional WordPress user
    wp user create $WP_USER $WP_USER_EMAIL \
        --user_pass=$WP_USER_PASSWORD \
        --role=author \
        --allow-root
    
    # Update WordPress URLs for HTTPS
    wp option update home "https://$DOMAIN_NAME" --allow-root
    wp option update siteurl "https://$DOMAIN_NAME" --allow-root
    
    echo "WordPress setup complete!"
else
    echo "WordPress already configured - skipping installation"
fi

# Configure PHP-FPM (only needs to run once, but safe to repeat)
sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 9000/g' /etc/php/8.2/fpm/pool.d/www.conf

# Start PHP-FPM
echo "Starting PHP-FPM..."
php-fpm8.2 -F