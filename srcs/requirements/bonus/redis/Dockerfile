FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        redis-server \
    && rm -rf /var/lib/apt/lists/*

COPY conf/redis.conf /etc/redis/redis.conf
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/setup.sh"]
