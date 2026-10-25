# Instructions for AI coding assistants

Read [DEVELOPMENT.md](DEVELOPMENT.md) first: the setup, where things are, how to test and commit.

- The repository is checked out at `/opt/hiddify-manager`; the panel is the submodule `services/panel/src`.
- Never edit `data/` or `generated/`: they are state and generated output.
- Admin UI changes go in `services/panel/src/hiddifypanel/admin_v2` only (the Flask-Admin pages are legacy).
- User UI changes go in `services/panel/src/hiddifypanel/user_front` (builds to `static/user-front/`, same model as admin_v2).
- Ask before restarting services: a panel restart migrates the server's database.

## Cursor Cloud specific instructions

Cloud Agent VMs do not boot systemd, so `systemctl` and `make build` do not work here (`make build` also installs the firewall). The environment start script launches MariaDB, Redis, the panel on `http://127.0.0.1:9000`, and the Admin V2 Vite dev server on `http://127.0.0.1:9001`. The panel is started with `HIDDIFY_ADMIN_V2_DEV=http://127.0.0.1:9001`, so Admin V2 requests on port 9000 are proxied to Vite.

`/opt/hiddify-manager` is the git checkout. `data/`, `.venv313`, and `generated/` are gitignored runtime state. Python is `/opt/hiddify-manager/.venv313` (3.13, via `uv`). The panel package is installed editable from `services/panel/src`.

The owner admin path (print it; do not commit it):

```bash
sudo bash -c 'cd /opt/hiddify-manager && source scripts/common/utils.sh && hiddify-panel-cli admin-path'
```

`ubuntu` is in the `hiddify-common` group so it can read `data/hiddify-panel/app.cfg` (mode 640). A shell that was opened before that group membership needs `sg hiddify-common`.

Panel tests, from `services/panel/src` (pytest is installed beside the venv, not into it):

```bash
sg hiddify-common -c 'PYTHONPATH=/opt/hiddify-pytest /opt/hiddify-manager/.venv313/bin/python -m pytest tests -p no:cacheprovider -q'
```

`/usr/sbin/policy-rc.d` exits 101 so package installs do not try to start systemd services. Chrome on this image upgrades `http://127.0.0.1` to HTTPS; `curl` against port 9000 is the reliable check. A browser check needs TLS in front of the panel, because the panel itself speaks HTTP.
