# Docker install (experimental)

Docker support in Hiddify Manager is **experimental**. Prefer a bare-metal install (`bash <(curl https://i.hiddify.com/beta)`) for production until the items below are closed.

## Quick start (published image)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/hiddify/Hiddify-Manager/main/scripts/common/docker-installer.sh) beta
```

Legacy redirects that still fetch `common/docker-installer.sh` are shimmed to the script above.

The installer:

1. Downloads `docker-compose.yml` + `docker.env` (no local Dockerfile required).
2. Activates `image: ghcr.io/hiddify/hiddify-manager:<tag>` and disables `build: .`.
3. Randomizes `MYSQL_PASSWORD` / `REDIS_PASSWORD` and **rewrites** `SQLALCHEMY_DATABASE_URI` / `REDIS_URI_MAIN` to match.

## Dedicated server vs co-existence

| Profile | File | Network | Privileged | Ports | Use when |
|---------|------|---------|------------|-------|----------|
| **Host (default)** | `docker-compose.yml` | `network_mode: host` | yes | all host ports (80/443 + proxies) | machine is mainly Hiddify |
| **Bridge** | `docker-compose.bridge.yml` | bridge | no | 80/TCP, 443/TCP+UDP only | other stacks already bind host ports |

Bridge mode needs URIs that use Compose DNS names:

```env
SQLALCHEMY_DATABASE_URI="mysql+mysqldb://hiddifypanel:PASS@mariadb:3306/hiddifypanel?charset=utf8mb4"
REDIS_URI_MAIN="redis://:PASS@redis:6379/1"
```

Host mode keeps `127.0.0.1` (MariaDB/Redis published on localhost only).

## Runtime limitations (not “stable” yet)

- Process model still uses a **python-systemctl** shim (not a dedicated container PID 1/supervisor).
- Default profile uses **privileged + host network** because HAProxy/Xray/hiddify-core open many listener ports.
- Bridge profile does **not** publish the full dynamic proxy port set; use host profile for full proxy coverage.
- Image entrypoint runs an apply/start pass on boot; editable `uv pip install -e` runs only when the panel source is bind-mounted or `HIDDIFY_PANEL_EDITABLE=1`.

## Develop against a mounted panel

```bash
docker compose -f docker-compose.yml -f docker-compose.override.yaml up -d
# on the host, after UI changes:
make ui
```

## Related issues

- Huge port publish / memory: [#4737](https://github.com/hiddify/Hiddify-Manager/issues/4737)
- Docker stable install / systemd bus: [#5134](https://github.com/hiddify/Hiddify-Manager/issues/5134)
