#!/bin/bash
set -euo pipefail

DB_PASSWORD="$(cat /run/secrets/db_password)"

cat > /root/.my.cnf <<EOF
[client]
user=${MYSQL_USER}
password=${DB_PASSWORD}
EOF

chmod 600 /root/.my.cnf

mkdir -p /var/backups/mariadb

cat > /etc/cron.d/mariadb-backup <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
MYSQL_DATABASE=${MYSQL_DATABASE}

0 3 * * * root /usr/local/bin/backup.sh >> /proc/1/fd/1 2>> /proc/1/fd/2
EOF

chmod 0644 /etc/cron.d/mariadb-backup

echo "[setup.sh] Backup service initialized."
echo "[setup.sh] Daily backup scheduled at 03:00."

exec cron -f
