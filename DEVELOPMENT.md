# Developing Hiddify Manager

Hiddify Manager is two repositories:

| Path | Repository | What it is |
|---|---|---|
| `/opt/hiddify-manager` | [Hiddify-Manager](https://github.com/hiddify/Hiddify-Manager) | install / service scripts, systemd units |
| `/opt/hiddify-manager/services/panel/src` | [Hiddify-Panel](https://github.com/hiddify/Hiddify-Panel) (git submodule) | the panel: Flask API, `admin_v2` (Vue) UI, config templates, ACME |

Develop on a Linux server or VM (Ubuntu 22.04 or newer), as root. A development machine **is** a Hiddify server: the
checkout lives where an installed Hiddify lives, so there is no copy step between your edits and what runs.

## Setup

```bash
sudo -i
git clone --recurse-submodules -b dev https://github.com/hiddify/Hiddify-Manager.git /opt/hiddify-manager
cd /opt/hiddify-manager
make build        # installs everything (MySQL, Redis, HAProxy, xray, hiddify-core, the panel, ...) in place
```

Then open `/opt/hiddify-manager` in VS Code (on a remote server: the *Remote - SSH* extension). The workspace settings
point to the panel's Python (`/opt/hiddify-manager/.venv313`); `.vscode/launch.json` has the run configurations.

The submodule has its own branch: work on `dev` in both.

```bash
git -C services/panel/src checkout dev
```

### What is tracked and what is not

Everything that is generated or is state lives outside the tracked files, so editing in place keeps `git status` clean:

- `data/`: the server's state (database config, certificates in `data/cert`, backups, logs). Never commit it.
- `generated/`: config files dumped by the panel (`haproxy.cfg`, `xray.json`, `hiddify-core.json`, ...).
- `.venv313/`, downloaded binaries (`services/*/bin`, hiddify-core, telemt, ...) and runtime files are in `.gitignore`.
- Locks are in `/run/hiddify/locks` (tmpfs).

A git checkout is detected (`is_dev_checkout` in `scripts/common/utils.sh`):

- the panel is installed **editable** from `services/panel/src`: a Python change needs only a panel restart;
- the auto-updater never overwrites the tree with a download. Update with git:

```bash
git pull --recurse-submodules && make build
```

## Everyday work

| Task | How |
|---|---|
| Run the panel with a debugger | stop the service, then the VS Code configuration **Admin V2 Dev (Flask + Vite)**: Flask (ASGI) on `127.0.0.1:9000` (HAProxy's panel backend), Vite on `9001` with hot reload for the admin UI |
| Restart the installed panel | `systemctl restart hiddify-panel` (it runs the editable source) |
| Apply configs after a template or setting change | the panel's *Apply* button, or `make apply` |
| Full reinstall of every service | `make build` |
| Build the admin + user UIs for production | `make ui` (admin → `static/admin-v2/`, user → `static/user-front/`; not in git) |
| Dump the server configs to look at them | VS Code *Dump server configs*, or `hiddify-panel-cli dump-server-configs /tmp/out` |
| Panel CLI | `source scripts/common/utils.sh && hiddify-panel-cli --help` (runs as the `hiddify-panel` user) |

Restarting the panel applies pending database migrations (`hiddifypanel/panel/init_db.py`, `_vNNN`) to the server's
database: keep a backup (`data/backup`) when you work on migrations.

### Where things are

- **Admin UI**: `services/panel/src/hiddifypanel/admin_v2` (Vue 3 + PrimeVue). The old Flask-Admin pages are legacy:
  do not change them.
- **User UI**: `services/panel/src/hiddifypanel/user_front` ([hiddify-user-front](https://github.com/hiddify/hiddify-user-front) submodule; React) — same model as `admin_v2`: Vite builds into `static/user-front/`, Flask serves `panel/user/templates/user_front.html` via the Vite manifest. Installers default to prebuilt `gh-pages`; CI / `make build-user-front` compile from source.
- **Admin API**: `hiddifypanel/panel/commercial/restapi/v2/admin/`.
- **Config templates** (HAProxy, xray, hiddify-core, sing-box, subscription links, ...):
  `hiddifypanel/proxy_v3/proxy_templates/<core>/<server|client>/`. The builtin ones are copied into the database when
  the panel starts (an admin can override them); `generated/` is rendered from the database.
- **Certificates**: `hiddifypanel/acme/` (Let's Encrypt / ZeroSSL; HAProxy answers the HTTP-01 challenges).
- **Services**: `services/<name>/{install,run,disable}.sh`; `scripts/install.sh` runs them.
- **Translations**: `hiddifypanel/translations.i18n/*.json`.

## Tests

The panel's tests are in `services/panel/tests` (pytest). The panel's venv has no pytest; install it next to it, not into it:

```bash
uv pip install --python /opt/hiddify-manager/.venv313/bin/python --target /tmp/pylib pytest
cd /opt/hiddify-manager/services/panel
PYTHONPATH=/tmp/pylib /opt/hiddify-manager/.venv313/bin/python -m pytest tests -p no:cacheprovider -q
```

Database tests use their own Redis database (15), never the live one. The admin UI type-checks with
`node_modules/.bin/vue-tsc --noEmit` in `admin_v2`.

## Committing

Commit the panel first, then the manager (it records the submodule's commit):

```bash
cd services/panel/src && git commit -am "fix: ..." && git push
cd /opt/hiddify-manager && git add services/panel/src <other files> && git commit -m "fix: ..." && git push
```

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `refactor:`,
...): the changelog is generated from them.

## Notes for AI assistants

- Follow this file. Work in `/opt/hiddify-manager`; never edit `data/` or `generated/` by hand (they are regenerated).
- Admin UI changes go in `admin_v2`; user UI changes go in `user_front`.
- Ask before restarting services on a server someone uses: a panel restart migrates its database.
