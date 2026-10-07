FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        apache2 \
        php \
        libapache2-mod-php \
        php-mysql \
        curl \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY conf/adminer.conf /etc/apache2/sites-available/adminer.conf
COPY tools/setup.sh /usr/local/bin/setup.sh

RUN a2dissite 000-default.conf \
    && a2enmod rewrite \
    && a2ensite adminer.conf \
    && echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf \
    && a2enconf servername \
    && chmod +x /usr/local/bin/setup.sh

EXPOSE 8081

ENTRYPOINT ["/usr/local/bin/setup.sh"]
