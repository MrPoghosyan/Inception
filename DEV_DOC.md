# Developer documentation

## Prerequisites

- A Linux Virtual Machine (project done and tested on Ubuntu 22.04 and on
  a Debian/Kali-based machine).
- `docker` and the `docker compose` plugin installed:

```bash
  sudo apt update
  sudo apt install -y docker.io docker-compose-v2
  sudo usermod -aG docker $USER   # log out/in afterwards
```

- `make`.

## Setting up the environment from scratch

1. Clone the repository and `cd` into it.
2. Check `srcs/.env`: adjust `DOMAIN_NAME` (must be `<login>.42.fr`),
   `MYSQL_DATABASE`, `MYSQL_USER`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`,
   `WP_USER`, `WP_USER_EMAIL`, `WP_TITLE`, `FTP_USER` if needed. **Never**
   put a password in this file.
3. Set real passwords in the `secrets/*.txt` files (they ship with
   placeholder values — change them before any real deployment):
   `db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`,
   `wp_user_password.txt`, `redis_password.txt`, `ftp_password.txt`.
4. Add the domain to `/etc/hosts` on the VM itself (needed for local
   testing from inside the VM), pointing to the VM's own address, e.g.:127.0.0.1 vapoghos.42.fr

   and, from the host machine that browses to the VM, point the same
   domain to the VM's IP address (see USER_DOC.md).

## Building and launching with Makefile / Docker Compose

```bash
make            # mandatory part only (mariadb, wordpress, nginx)
make bonus      # mandatory part + all self-built bonus services
make bonus_cA   # additionally pulls and starts cAdvisor
make down       # docker compose down
make re         # fclean then all (full rebuild from a clean state)
```

Under the hood:

- `make`/`make bonus` call `setup` first (creates the host directories the
  named volumes bind to under `/home/<login>/data`), then
  `docker compose -f srcs/docker-compose.yml up -d --build [services...]`.
  `make` passes explicit service names (`mariadb wordpress nginx`) so only
  the mandatory part is built/started; `make bonus` passes no service name,
  which makes Compose start every service that does not have an active
  profile — i.e. everything except `cadvisor`.
- `make bonus_cA` runs
  `docker compose -f srcs/docker-compose.yml --profile cadvisor up -d --build cadvisor`.
  `cadvisor` is the only service declared with `profiles: [cadvisor]` in
  `docker-compose.yml`, so it is excluded from both `make` and `make bonus`
  and only starts when this profile is explicitly activated.

All self-built images (`mariadb`, `wordpress`, `nginx`, `redis`, `ftp`,
`static-site`, `adminer`, `backup`) are built from the `Dockerfile`s in
`srcs/requirements/*/` and `srcs/requirements/bonus/*/`, using `srcs/.env`
for non-sensitive variables and `secrets/*.txt` mounted at
`/run/secrets/*` for passwords. The `cadvisor` service is the single,
explicitly documented exception: it uses the official
`gcr.io/cadvisor/cadvisor` image pinned to `v0.49.1`, pulled directly, since
it is a free-choice bonus service and not part of the mandatory
requirements (see README.md for the justification).

## Managing containers and volumes

```bash
docker compose -f srcs/docker-compose.yml ps -a
docker compose -f srcs/docker-compose.yml logs -f [service]
docker compose -f srcs/docker-compose.yml exec wordpress bash
docker compose -f srcs/docker-compose.yml exec mariadb bash
docker volume ls
docker volume inspect srcs_db_data
```

To rebuild a single service after editing its Dockerfile/config:

```bash
docker compose -f srcs/docker-compose.yml up -d --build wordpress
```

## Where data is stored and how it persists

- `db_data` volume → bind-backed by `/home/<login>/data/db` on the host,
  mounted at `/var/lib/mysql` in the `mariadb` container.
- `wp_data` volume → bind-backed by `/home/<login>/data/wordpress` on the
  host, mounted at `/var/www/html` in the `wordpress`, `nginx` and `ftp`
  containers (so NGINX can read the WordPress static files directly, PHP
  execution is proxied to `wordpress:9000`, and files can be managed over
  FTP).
- `backup_data` volume → bind-backed by `/home/<login>/data/backup` on the
  host, mounted at `/var/backups/mariadb` in the `backup` container.

All three directories are created by `make setup` (called automatically by
`make`/`make bonus`) and removed by `make fclean`. Because they are Docker
**named volumes** (not raw bind mounts) backed by these paths via
`driver_opts`, `docker volume rm` / `docker compose down -v` also cleans
them up.

## Notes on entrypoints (PID 1 compliance)

Every self-built service's entrypoint script performs its (idempotent)
first-run setup, then uses `exec` to replace itself with the actual
long-running daemon, so that the daemon becomes PID 1 and receives Docker's
signals directly (no wrapper process in between):

- `mariadb`'s `init.sh` initializes the data directory and creates the
  database/user only once (detected by the absence of
  `/var/lib/mysql/mysql` — the Debian package pre-populates this at build
  time, so it is explicitly cleared in the Dockerfile), then `exec`s
  `mariadbd`.
- `wordpress`'s `setup.sh` waits for MariaDB, downloads/configures
  WordPress and the Redis plugin only once (detected by the absence of
  `wp-config.php`), then `exec`s `php-fpm -F`.
- `nginx`'s `setup.sh` generates a self-signed certificate once, then
  `exec`s `nginx -g "daemon off;"`.
- `redis`'s `setup.sh` reads the Redis password from its secret and
  `exec`s `redis-server ... --requirepass`.
- `ftp`'s `setup.sh` builds the vsftpd virtual-user database (via process
  substitution, so the plaintext password is never written to disk) and
  `exec`s `vsftpd`.
- `adminer`'s `setup.sh` fixes the Apache listening port and downloads
  Adminer once, then `exec`s `apache2ctl -D FOREGROUND`.
- `backup`'s `setup.sh` writes the MariaDB credentials file, installs the
  cron schedule (baking in the needed environment variables, since cron
  jobs do not inherit the container's environment), then `exec`s `cron -f`.
- `static-site` is a plain NGINX serving a static page; its `ENTRYPOINT`
  runs `nginx -g "daemon off;"` directly.

No `tail -f`, `sleep infinity`, or similar hacky patches are used anywhere;
each container's foreground process is the actual service, correctly
acting as PID 1.

## Testing approach used during development

- Each service was first built and run **in isolation** (`docker build` +
  `docker run`, manually wiring the needed secrets/volumes/network) before
  being wired into `docker-compose.yml`, to catch configuration issues
  early without the complexity of the full stack.
- `bash -n <script>` was used to catch shell syntax errors before running
  scripts.
- `docker compose config` was used to validate the Compose file (YAML
  syntax, secret/volume references) without starting any container.
- Crash-recovery was tested by sending `SIGKILL` to PID 1 **from inside**
  the container (`docker exec <name> kill -9 1`) rather than using
  `docker kill`/`docker stop`, because Docker intentionally suppresses the
  `restart` policy after an explicit, external stop/kill — only an
  unexpected, internal process death triggers it, which is what the
  subject's "restart in case of a crash" requirement is actually about.
