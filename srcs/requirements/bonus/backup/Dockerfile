FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        mariadb-client \
        cron \
    && rm -rf /var/lib/apt/lists/*

COPY tools/backup.sh /usr/local/bin/backup.sh
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/backup.sh /usr/local/bin/setup.sh

ENTRYPOINT ["/usr/local/bin/setup.sh"]
