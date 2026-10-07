#!/bin/bash
set -e

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

mkdir -p /etc/vsftpd

db_load -T -t hash -f <(printf '%s\n%s\n' "${FTP_USER}" "${FTP_PASSWORD}") /etc/vsftpd/virtual_users.db

echo "[setup.sh] Starting vsftpd..."
exec vsftpd /etc/vsftpd.conf
