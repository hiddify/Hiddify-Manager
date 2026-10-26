# Using an external (remote) MySQL/MariaDB and Redis

By default Hiddify installs a local MariaDB (`hiddify-mysql.service`, port 3306 on
`127.0.0.1`) and Redis (`127.0.0.1:6379`) and keeps their passwords in `data/`.
The panel's database layer is plain SQLAlchemy, so a server with limited
resources (or a fleet of panels sharing one database server) can point the
panel at a remote MySQL/MariaDB and/or Redis instead.

The connection URIs are:

```bash
# MySQL/MariaDB (mysqlclient driver; the pure-Python `mysql+pymysql://`
# scheme also works when the C driver cannot be built)
SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:STRONG_PASS@db.example.com:3306/hiddifypanel?charset=utf8mb4"

# Redis
REDIS_URI_MAIN="redis://:STRONG_PASS@redis.example.com:6379/0"
```

The database name, user, and charset are free choices — any URI that SQLAlchemy
accepts works. Set up a MySQL/MariaDB (a recent MySQL 8.x or MariaDB 10.x/11.x)
on the remote server and create the user before installing Hiddify:

```sql
CREATE DATABASE IF NOT EXISTS hiddifypanel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'hiddifypanel'@'<panel-ip-or-%>' IDENTIFIED BY 'STRONG_PASS';
GRANT ALL PRIVILEGES ON hiddifypanel.* TO 'hiddifypanel'@'<panel-ip-or-%>';
FLUSH PRIVILEGES;
```

## Bare-metal server

1. Export the URIs in the shell that will run the installer — they are read
   from the environment at install/apply time (`scripts/panel/run.sh`):

    ```bash
    export SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:STRONG_PASS@db.example.com:3306/hiddifypanel?charset=utf8mb4"
    # export REDIS_URI_MAIN="redis://:STRONG_PASS@redis.example.com:6379/0"  # optional
    bash <(curl https://i.hiddify.com/beta)   # or scripts/install.sh of a checkout
    ```

2. The installer then skips the local MariaDB (and Redis, when
   `REDIS_URI_MAIN` is set) and runs `hiddify-panel-cli init-db` against your
   remote database, so the schema is created there on first install.

### Persistence across updates

`services/panel/run.sh` writes the URIs into the panel's durable config
(`data/hiddify-panel/app.cfg`) together with a marker:

```ini
SQLALCHEMY_DATABASE_URI ='mysql+mysqldb://hiddifypanel:...@db.example.com:3306/hiddifypanel?charset=utf8mb4'
HIDDIFY_EXTERNAL_DB=True
```

Every later install/update **re-uses the persisted URI**, even when the env
vars are no longer exported, and keeps skipping the local MariaDB/Redis
install. Use the same export (or `hiddify apply-users`) for the switch to happen
deliberately.

To go back to the built-in database:

1. remove the `HIDDIFY_EXTERNAL_DB=True` (and `HIDDIFY_EXTERNAL_REDIS=True`)
   lines from `data/hiddify-panel/app.cfg`;
2. unset the env vars
3. re-run the installer — it reinstalls the local MariaDB/Redis; your remote
   data stays untouched, and the panel starts on a fresh local database:
   run `hiddify-panel-cli backup` before switching (over the remote database),
   then restore the backup to move the users.

The local MariaDB of a previous install keeps running with its data when the
switch to an external database happens. Stop it if you no longer need it:

```bash
systemctl disable --now hiddify-mysql
```

## Docker

`docker.env` holds both URIs for the container. Point them at your remote
servers and don't need the built-in containers either; remove the
`mariadb`/`redis` services and the `hiddifymanager` `depends_on` block from
`docker-compose.yml`, or keep everything and disable the dependencies with the
shipped override file:

```bash
docker compose -f docker-compose.yml -f docker-compose.external-db.yml up -d
```

`depends_on: !reset []` requires Docker Compose v2.24+; without it, edit
`docker-compose.yml` directly — the idle local containers are harmless but
waste memory and disk.

## Notes

- The panel talks to the database constantly (every request, user
  subscriptions, node sync). A remote database over the internet adds latency
  everywhere, so it makes sense mainly on a fast link (same datacenter/LAN) —
  not across continents.
- Backups (`hiddify-panel-cli backup`) and migrations run through the same
  SQLAlchemy connection, so they work unchanged against a remote database.
- The panel hardens its connection with `READ COMMITTED` isolation and
  `pool_pre_ping` (see `services/panel/src/hiddifypanel/database.py`), which is
  specifically tuned for MySQL/MariaDB and keeps working with a remote server.
- A single database shared by multiple panels is not an officially supported
  mode: each panel manages its own users and domains, so sharing is at your
  own risk.
