#!/bin/bash

# waiting for MariaDB
until mysqladmin ping -h"mariadb" -u"$MDB_USER" -p"$MDB_USER_PASS" --silent; do
  echo "⏳ Waiting for MariaDB to be ready..."
  sleep 2
done

if [ ! -f wp-config.php ]; then

	echo "Creating wp-config.php..."
	wp config create \
		--dbname="$MDB_NAME" \
		--dbuser="$MDB_USER" \
		--dbpass="$MDB_USER_PASS"\
		--dbhost="mariadb" \
		--path=/var/www/wordpress \
		--allow-root
	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WEBSITE_TITLE" \
		--admin_user="$WP_ADMIN_LOGIN" \
		--admin_password="$WP_ADMIN_PASS" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email \
		--allow-root

	echo "Creating wp user..."
	wp user create "$WP_USER_LOGIN" "$WP_USER_EMAIL" \
		--role=author \
		--user_pass="$WP_USER_PASS" \
		--allow-root

	echo "WordPress installation ended."

else
	echo "WordPress is already configured."
fi

echo "Launching PHP-FPM..."
exec /usr/sbin/php-fpm7.4 -F