#!/bin/bash
set -e

sed -i 's/Listen 80/Listen 8081/' /etc/apache2/ports.conf

mkdir -p /var/www/adminer

if [ ! -f /var/www/adminer/index.php ] || [ ! -s /var/www/adminer/index.php ]; then
    echo "[setup.sh] Downloading Adminer..."
    curl -sSL -o /var/www/adminer/index.php \
        https://www.adminer.org/latest.php
fi

chown -R www-data:www-data /var/www/adminer

echo "[setup.sh] Starting apache2..."
exec apache2ctl -D FOREGROUND
