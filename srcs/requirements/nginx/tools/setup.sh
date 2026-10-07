#!/bin/bash
set -e

mkdir -p /etc/nginx/ssl

if [ ! -f /etc/nginx/ssl/inception.crt ]; then
    echo "[setup.sh] Generating self-signed TLS certificate for ${DOMAIN_NAME}..."
    # NOTE: RSA 2048-bit is used here; RSA 4096-bit would offer a stronger
    # security level, at the cost of slightly slower TLS handshakes.
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=AM/ST=Yerevan/L=Yerevan/O=42/OU=42/CN=${DOMAIN_NAME}"
fi

echo "[setup.sh] Starting nginx..."
exec nginx -g "daemon off;"
