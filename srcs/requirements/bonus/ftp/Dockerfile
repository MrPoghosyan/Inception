FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        vsftpd \
        db-util \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY conf/vsftpd_virtual /etc/pam.d/vsftpd_virtual
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

RUN mkdir -p /var/run/vsftpd/empty

EXPOSE 21 21100-21110

ENTRYPOINT ["/usr/local/bin/setup.sh"]
