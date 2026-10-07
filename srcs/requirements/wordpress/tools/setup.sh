#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
REDIS_PASSWORD=$(cat /run/secrets/redis_password)

echo "[setup.sh] Waiting for MariaDB to be ready..."
until mariadb -h mariadb -u "${MYSQL_USER}" -p"${DB_PASSWORD}" -e "SELECT 1;" \
	>/dev/null 2>&1; do
	sleep 2
done
echo "[setup.sh] MariaDB is ready."

if [ ! -f /var/www/html/wp-config.php ]; then
	echo "[setup.sh] First run: downloading and installing WordPress..."

	curl -sS -o /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
	tar -xzf /tmp/wordpress.tar.gz -C /tmp/
	cp -r /tmp/wordpress/. /var/www/html/
	rm -rf /tmp/wordpress/ /tmp/wordpress.tar.gz

	cd /var/www/html

	wp config create \
		--dbname="${MYSQL_DATABASE}" \
		--dbuser="${MYSQL_USER}" \
		--dbpass="${DB_PASSWORD}" \
		--dbhost="mariadb" \
		--allow-root
	
	#Պաշտպանություն (defense-in-depth, WordPress-ի կողմից). hardcode WP_HOME/WP_SITEURL
	wp config set WP_HOME "https://${DOMAIN_NAME}" --allow-root
	wp config set WP_SITEURL "https://${DOMAIN_NAME}" --allow-root

	wp core install \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}" \
		--skip-email \
		--allow-root

	wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--role=author \
		--user_pass="${WP_USER_PASSWORD}" \
		--allow-root

	wp config set WP_REDIS_HOST "redis" --allow-root
	wp config set WP_REDIS_PORT 6379 --raw --allow-root
	wp config set WP_REDIS_PASSWORD "${REDIS_PASSWORD}" --allow-root

	wp plugin install redis-cache --activate --allow-root
	wp redis enable --allow-root

	chown -R www-data:www-data /var/www/html
	echo "[setup.sh] WordPress installed."
fi

echo "[setup.sh] Starting php-fpm..."
exec /usr/sbin/php-fpm8.2 -F
