---
name: hiddify-dev
description: Develop features and fix bugs in Hiddify Manager (install/service scripts, the Flask panel, the admin_v2 Vue UI, config templates). Use for any code change, bug report, stack trace or UI request in this repository.
---

# Developing and fixing bugs in Hiddify Manager

Read `DEVELOPMENT.md` once per session; this skill adds the working rules on top of it.

## The two repositories

| Path (relative to the checkout) | What |
|---|---|
| `.` | Hiddify-Manager: `scripts/` (install, apply, commander), `services/<name>/{install,run,disable,reload}.sh`, systemd units, `Dockerfile` |
| `services/panel/src` | Hiddify-Panel (git **submodule**): Flask API, `admin_v2` UI, config templates, migrations, ACME |

Inside the panel (`services/panel/src/hiddifypanel/`):

- `admin_v2/` admin UI (Vue 3 + PrimeVue, Sakai). The **only** admin UI to change.
- `user_front/` user UI (its own submodule, React). Builds to `static/user-front/`.
- `panel/commercial/restapi/v2/admin/` admin API used by admin_v2.
- `panel/init_db.py` migrations `_vNNN(child_id)`; `models/config_enum.py` settings.
- `proxy_v3/proxy_templates/` config templates and defaults (`outbounds/defaults.yaml`, ...).
- `hutils/` helpers; `panel/cli.py` CLI and scheduled jobs (backup); `scheduler.py` job schedule.
- `translations.i18n/*.json` translations, shared by the panel and admin_v2 (`t('...')`).

## Hard rules

- Never edit `data/` (server state) or `generated/` (rendered configs): fix the code that produces them.
- Never edit the legacy Flask-Admin pages (`panel/admin/*Admin.py`, `templates/master.html`, `admin-layout.html`)
  for features. Only touch them to stop them from crashing.
- **Ask before** restarting the panel or services, running `make build` / apply / apply-users on the live server,
  pushing, commenting on or closing PRs. A panel restart runs pending migrations on the server's database.
- Commit the submodule first, then the outer repo. Conventional Commits (`fix:`, `feat:`, ...).

## Fixing a bug

1. **Find the cause before the fix.** Read the full stack trace and follow it into the code; reproduce or check
   the live state read-only (`journalctl -u <unit>`, `systemctl cat <unit>`, the files in `generated/`, logs in
   `data/log`). Say what the cause is in one or two sentences.
2. **Fix it where it comes from**, not where it shows. Examples from this codebase:
   - a missing binary in the Docker image came from `install_run` choosing `disable.sh` because settings are not
     read at image build; fix in `scripts/install.sh`, not a one-off `Dockerfile` line;
   - a legacy page crashing on a missing endpoint: gate the legacy blueprint, do not re-add the endpoint.
3. Check every other caller of what you change (`grep` the name across Python, shell, templates and Vue).
4. Keep the change in the style of the surrounding code: comment density, naming, helpers already there
   (`hconfig`, `set_hconfig`, `add_config_if_not_exist`, `hutils.*`, `run_timed`, `run_logged`).
5. Verify (see below) and report what was and was not verified.

## Common change recipes

- **New setting**: add it in `models/config_enum.py` (category, `ApplyMode`), a migration `_vNNN` in `init_db.py`
  (next number above the highest; `add_config_if_not_exist`), and `config.<key>.label/description` in **every**
  `translations.i18n/*.json` (insert the key; do not re-sort or re-indent the files).
- **Shell services**: each `services/<x>/` has `install.sh`, `run.sh`, `disable.sh`, and `reload.sh` (used by
  `scripts/apply_users.sh`). systemd units are symlinked from the repo: after changing a unit, the service's
  `run.sh` must `systemctl daemon-reload`. Docker mode (`DOCKER_MODE=true`) has no real systemd.
- **Commander chain** (panel → root scripts): `panel/run_commander.py` → `sudo scripts/common/commander.py`
  (click) → `scripts/*.sh`. A new argument has to go through all three.
- **Telegram bot messages**: HTML parse mode; escape with `html.escape`; captions ≤ 1024 characters.
- **Network lookups at install** (OONI, IP detection): always time-capped with an offline fallback.

## admin_v2 (Vue) UI

Build with Vue 3 (`<script setup lang="ts">`), strict TypeScript, and PrimeVue using the Sakai template and theme.
Make it elegant, user-friendly, mobile-first, and fully responsive, with light/dark mode and clear loading, empty,
and error states. Keep the code fully type-safe (no `any`), modular (small components, composables, services,
types, stores), and easy to maintain, preferring PrimeVue components over custom ones and avoiding unnecessary
libraries.

In practice:

- Layout: `src/features/<feature>/{api.ts, components/, views/}`; shared code in `src/shared/{components,
  composables,utils}`; app shell, i18n, theme and API client in `src/core/`. Put new code in the matching place.
- API calls live in the feature's `api.ts` with typed request/response interfaces; components do not call
  `fetch` directly.
- Colours come from PrimeVue/Sakai tokens (`var(--p-...)`, `var(--text-color)`, `var(--surface-...)`), never
  fixed hex values alone, so dark mode works. Check RTL (Persian): use logical properties
  (`margin-inline-start`, `inset-inline-end`).
- Every user-visible string goes through `t('...')` with keys in `translations.i18n/*.json` (at least `en` and `fa`).
- Every view that loads data shows a loading state (Skeleton / ProgressSpinner), an empty state, and an error
  state with a retry.
- Warnings that are not errors (e.g. "needs reinstall") must not look like errors: show them on hover/focus or
  after the change, and say what is needed when saving (`ApplyNotice`).
- The dev page is served by Vite (`9001`), proxied by the panel; the production build is `make ui`.

## Verifying

- Python: `python3 -m py_compile <files>`; tests with pytest from `services/panel` using a pytest installed next
  to the venv (see `DEVELOPMENT.md`). Compare failures with a baseline on a clean `git stash` in the submodule,
  since some tests already fail on `dev`.
- Shell: `bash -n <script>`; logrotate configs: `logrotate -d <file>`.
- Vue: `node_modules/.bin/vue-tsc --noEmit` in `admin_v2` and check only the files you touched (other files
  already have errors).
- Functions with network calls: run them with the panel's Python
  (`/opt/hiddify-manager/.venv313/bin/python`) and `unittest.mock` to test the offline path too.
- JSON translations: `python3 -c "import json; json.load(open(f))"` for each file you edited.

## Reporting

End with what changed (file links), why, what you verified, what you did not (e.g. "not run on the server: needs
a panel restart"), and anything that needs the user's decision.
