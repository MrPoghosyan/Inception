# User documentation

## What services does the stack provide?

### Mandatory
- **A WordPress website**, reachable at `https://vapoghos.42.fr`.
- **A WordPress admin panel**, reachable at `https://vapoghos.42.fr/wp-admin`.
- Behind the scenes: an NGINX reverse proxy (the only public entry point for
  the mandatory part) and a MariaDB database (not directly reachable from
  outside the stack).

### Bonus (started with `make bonus` / `make bonus_cA`)
- **Redis** — invisible to the end user, but speeds up every page load by
  caching database queries.
- **FTP** — `ftp://<host-ip>:21`, to upload/download the WordPress files
  directly.
- **Static website** — `http://<host-ip>:8080`, a separate, personal page
  unrelated to WordPress.
- **Adminer** — `http://<host-ip>:8081`, a database admin panel for
  MariaDB.
- **Backup** — invisible to the end user; runs automatically every night.
- **cAdvisor** — `http://<host-ip>:8082`, a live dashboard of CPU/memory/
  network usage for every running container.

## Starting and stopping the project

From the root of the repository:

```bash
make            # mandatory part only: mariadb, wordpress, nginx
make bonus      # mandatory part + redis, ftp, static-site, adminer, backup
make bonus_cA   # additionally starts cAdvisor
make stop       # pause every running container without removing it
make start      # resume previously stopped containers
make down       # stop and remove all containers (data is kept)
make fclean     # stop everything AND delete the persisted data/volumes
```

Check that everything is running with:

```bash
make ps
```

You should see each container you started listed as `Up`.

## Accessing the website

1. Make sure `vapoghos.42.fr` resolves to your VM's IP. On the machine you
   browse from, add to `/etc/hosts` (or
   `C:\Windows\System32\drivers\etc\hosts` on Windows): <VM_IP> vapoghos.42.fr

2. Open `https://vapoghos.42.fr` in your browser.
3. Since the TLS certificate is self-signed, the browser will show a
   security warning the first time — this is expected, accept/continue.
4. To manage the site, go to `https://vapoghos.42.fr/wp-admin`.

## Accessing the bonus services

Replace `<host-ip>` with the VM's IP address (find it with `hostname -I` on
the VM itself).

- **FTP**: connect with any FTP client (e.g. FileZilla) or
  `curl ftp://<host-ip>:21/ --user <ftp_user>:<ftp_password>`, in **passive**
  mode. You will land directly inside the WordPress files directory.
- **Static website**: `http://<host-ip>:8080`.
- **Adminer**: `http://<host-ip>:8081`. On the login screen, use:
  - System: MySQL
  - Server: `mariadb`
  - Username / Password: the WordPress database credentials (see below)
  - Database: the WordPress database name (see below)
- **cAdvisor**: `http://<host-ip>:8082/containers/`.

## Locating and managing credentials

- Non-sensitive configuration (domain name, database name, usernames) is in
  `srcs/.env`.
- Actual passwords are stored as plain text files in `secrets/` at the repo
  root (`db_password.txt`, `db_root_password.txt`, `wp_admin_password.txt`,
  `wp_user_password.txt`, `redis_password.txt`, `ftp_password.txt`). This
  folder is git-ignored and must never be committed.
- The WordPress **administrator** username is set by `WP_ADMIN_USER` in
  `.env`, its password is `secrets/wp_admin_password.txt`.
- A second, non-administrator WordPress user is set by `WP_USER` in `.env`,
  its password is `secrets/wp_user_password.txt`.
- The FTP username is `FTP_USER` in `.env`, its password is
  `secrets/ftp_password.txt`.
- To change any credential: edit the corresponding secret file **before**
  the first `make up`/`make bonus` (they are only applied when the
  relevant service is first initialized), then run `make fclean` followed
  by `make`/`make bonus` to re-provision from scratch.

## Checking that services are running correctly

```bash
make ps
docker compose -f srcs/docker-compose.yml logs    # combined logs
docker logs nginx
docker logs wordpress
docker logs mariadb
docker logs redis
docker logs ftp
docker logs adminer
docker logs backup
docker logs cadvisor
```

A healthy mandatory stack shows `mariadb`, `wordpress`, `nginx` all `Up`,
the site loads over HTTPS, and you can log in at `/wp-admin`. A healthy
bonus stack additionally shows `redis`, `ftp`, `static-site`, `adminer`,
`backup` (and, if started, `cadvisor`) all `Up`.

## Backups

A backup of the WordPress database is created automatically every day at
03:00 inside the `backup` container, and stored on its own named volume
(backups older than 7 days are deleted automatically). To trigger one
manually:

```bash
docker exec backup /usr/local/bin/backup.sh
docker exec backup ls -la /var/backups/mariadb/
```
