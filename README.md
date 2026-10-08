*This project has been created as part of the 42 curriculum by vapoghos.*

# Inception

## Description

Inception is a system administration project whose goal is to set up a small
web infrastructure using **Docker** and **Docker Compose**, with each service
running in its own dedicated container built from a custom `Dockerfile` (no
ready-made images pulled from Docker Hub, except the base Alpine/Debian image
and, for the free-choice bonus service, one explicitly documented exception —
see the Bonus section).

The mandatory stack is made of three services:

- **NGINX** — the single entry point of the infrastructure, serving HTTPS
  (TLSv1.2/TLSv1.3 only) on port 443, and nothing else.
- **WordPress + php-fpm** — the CMS, without any embedded web server; it only
  speaks FastCGI to NGINX.
- **MariaDB** — the database used by WordPress, with no web server involved.

Two named Docker volumes persist data on the host (`/home/vapoghos/data`):
one for the WordPress database, one for the WordPress website files. All
mandatory containers communicate over a dedicated `docker-network` and are
configured to restart automatically on crash.

## Bonus services

In addition to the mandatory part, six bonus services were implemented:

- **Redis** — object cache for WordPress (via the `redis-cache` plugin and
  the `php-redis` extension), reducing repeated database queries.
- **FTP server (vsftpd)** — a virtual-user FTP server pointing at the same
  named volume as the WordPress files, so they can be managed from an FTP
  client.
- **Static website** — a standalone, personalised HTML/CSS page served by
  its own NGINX container (no PHP), on a separate port.
- **Adminer** — a lightweight, single-file PHP database-administration tool
  served by Apache, to inspect/manage the MariaDB database from a browser.
- **Backup service** — a cron-based container that runs `mariadb-dump` daily
  at 03:00, compresses the dump, stores it on a dedicated named volume, and
  prunes backups older than 7 days.
- **cAdvisor** — a container resource-monitoring dashboard (CPU, memory,
  network, disk I/O per container), chosen as the free-choice bonus service
  because real-time container observability is directly relevant to
  cybersecurity (anomaly detection, resource-abuse/compromise indicators,
  audit/compliance).

See [Instructions](#instructions) for how to start each layer independently.

## Project structure
```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                  # Gitignored Docker secrets
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── ftp_password.txt
│   ├── redis_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── bonus/
            ├── redis/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── tools/
            ├── ftp/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── tools/
            ├── static-site/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── html/
            ├── adminer/
            │   ├── Dockerfile
            │   ├── conf/
            │   └── tools/
            └── backup/
                ├── Dockerfile
                └── tools/
```

## Instructions

See [DEV_DOC.md](./DEV_DOC.md) for full setup/build instructions, and
[USER_DOC.md](./USER_DOC.md) for how to use the running website.

Quick start:

```bash
make         # mandatory part only (mariadb, wordpress, nginx)
make bonus   # mandatory part + all self-built bonus services
make bonus_cA   # adds cAdvisor on top of whatever is already running
make down    # stops and removes every container
make fclean  # stops everything and wipes persisted data
```

## Design choices

### Virtual Machine vs Docker
A VM virtualizes an entire operating system (its own kernel, drivers, init
system) on top of a hypervisor, which makes it heavy to boot and
resource-hungry. A Docker container shares the host's kernel and only
isolates the process, filesystem, and network namespace, which makes it
lightweight and fast to start. We use one VM as the host (required by the
subject) and Docker containers *inside* it to isolate each service, giving
us reproducibility without the overhead of one VM per service.

### Secrets vs Environment Variables
Environment variables (`.env`, `env_file`) are convenient but are visible in
`docker inspect`, in the container's environment, and can leak into logs or
crash dumps. Docker **secrets** are mounted as files under
`/run/secrets/<name>` only inside the container that declares them, are not
part of the image layers, and are not shown by `docker inspect`. For this
reason, actual passwords (DB root/user, WordPress admin/user, Redis, FTP)
are stored as secrets, while non-sensitive configuration (domain name,
database name, usernames) stays in `.env`.

### Docker Network vs Host Network
`network: host` makes a container share the host's network namespace
entirely, removing isolation and creating port-conflict risks; it is also
explicitly forbidden by the subject. A user-defined **bridge network**
(`docker-network`) instead gives each container its own network namespace,
lets containers resolve each other by service name (`mariadb`, `wordpress`,
`nginx`, `redis`, ...), and only exposes the ports we explicitly publish
(443 on NGINX for the mandatory part; separate, documented ports for bonus
services that are meant to be reached directly, such as FTP or Adminer).

### Docker Volumes vs Bind Mounts
A bind mount maps an arbitrary host path directly into the container and
depends entirely on the host's filesystem structure and permissions, which
is fragile and not portable. A named **volume** is managed by the Docker
daemon itself, has a well-defined lifecycle independent from any container,
and is the recommended way to persist data. The subject additionally
requires that these named volumes physically live under
`/home/vapoghos/data` on the host, which we achieve with the `local` driver
and `driver_opts` (`type: none`, `o: bind`), giving us a named volume that
is Docker-managed but still backed by a specific host directory.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Docker Compose profiles](https://docs.docker.com/compose/profiles/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WP-CLI documentation](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [Redis documentation](https://redis.io/docs/)
- [redis-cache plugin](https://wordpress.org/plugins/redis-cache/)
- [vsftpd documentation](https://security.appspot.com/vsftpd.html)
- [Adminer](https://www.adminer.org/)
- [cAdvisor](https://github.com/google/cadvisor)
- [PID 1 and zombie reaping in containers](https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/)

### AI usage

An AI assistant (Claude) was used throughout this project as a **teaching
and debugging aid**, not as a code generator: each file was written and run
by hand, and the assistant's role was to explain, before and after writing
any command or line, what it does, why it is needed, and which part of the
subject it satisfies. Concretely, the assistant was used to:

- Explain Docker/Compose/Linux concepts (PID 1 and the `exec` pattern, bind
  mounts vs named volumes, Docker secrets vs env files, FTP passive mode,
  PAM virtual users, seccomp, multi-stage builds, bash file-test operators,
  heredocs, cron environment isolation, etc.) before each file was written.
- Review hand-written Dockerfiles, configuration files and shell scripts for
  correctness and consistency with the rest of the project.
- Diagnose real runtime failures encountered during testing (e.g. a MariaDB
  datadir pre-initialized at build time by the Debian package, a `-p`
  password flag passed with a stray space, a typo turning `mariadb` into
  `maiadb` and breaking DNS resolution inside the Docker network, vsftpd
  crashing with `SIGSEGV` due to its internal seccomp sandbox conflicting
  with the container runtime, `db_load` not supporting `-f -` for stdin, a
  Host-header-based access-control bypass against the NGINX vhost, a GitHub
  release URL silently returning an empty file for Adminer, and Docker's
  restart policy being intentionally suppressed after an explicit
  `docker stop`/`kill`).

All generated explanations and suggested fixes were tested step by step
(isolated single-container tests before multi-container integration,
`bash -n` syntax checks, `docker compose config` validation, crash/restart
tests) before being accepted, in line with the project's AI usage
guidelines.
