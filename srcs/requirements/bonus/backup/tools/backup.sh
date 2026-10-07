#!/bin/bash
set -euo pipefail

BACKUP_DIR="/var/backups/mariadb"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_FILE="${BACKUP_DIR}/${MYSQL_DATABASE}_${TIMESTAMP}.sql.gz"

mkdir -p "${BACKUP_DIR}"

echo "[backup.sh] Creating backup: ${BACKUP_FILE}"

if ! mariadb-dump \
        --defaults-extra-file=/root/.my.cnf \
        --host=mariadb \
        --single-transaction \
        --routines \
        --triggers \
        "${MYSQL_DATABASE}" | gzip > "${BACKUP_FILE}"
then
    echo "[backup.sh] Backup failed."
    rm -f "${BACKUP_FILE}"
    exit 1
fi

echo "[backup.sh] Backup completed successfully."

find "${BACKUP_DIR}" \
    -type f \
    -name "*.sql.gz" \
    -mtime +7 \
    -delete
