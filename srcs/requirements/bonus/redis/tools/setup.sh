#!/bin/bash
set -e

REDIS_PASSWORD=$(cat /run/secrets/redis_password)

exec redis-server /etc/redis/redis.conf --requirepass "${REDIS_PASSWORD}"
