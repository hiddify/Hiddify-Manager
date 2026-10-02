# Hiddify Manager v13 — Main Changes since v12

## Summary

- **Multi-node**: nodes keep working on their own when the connection to the central panel fails, and sync again once it is back.
- **Central control of node domains**: the central panel decides which nodes' domains and proxies appear in subscriptions.
- **New interactive admin panel**: the central panel shows all the important information for every node.
- **New proxy engine**: 218 built-in proxies covering many protocol, transport and security combinations. Every detail is editable.
- **Shared settings, edited once**: common proxy settings live in one place instead of in every proxy.
- **Selectable proxies per domain.**
- **Xray and sing-box proxies work together.**
- **Split XHTTP**: upload and download can use different layers (HTTP, TLS, TLS H2, QUIC) and different domain types (CDN, relay, REALITY, direct).
- **Latest Xray**: VLESS encryption and automatic detection of when `insecure` is needed.
- **Ports 443 and 80 whenever possible**: active probing by the GFW finds no trace of a proxy.
- **Faster transport**: high-performance QUIC and 50% faster TLS termination.
- **DNS tunnels**: VayDNS, Slipstream and MasterDnsVPN, all running together.
- **New protocols**: AnyTLS, Snell and SOCKS.
- **All data in one folder**: everything lives in `/opt/hiddify-manager/data`, so back up only that path.
- **50% less panel memory.**
- **Utils page** (runs in the browser only): share-link decoder and editor, plus Base64 and URL encoders.
- **Full Persian support**: RTL layout, dark mode and a mobile-friendly layout.
- **Security fixes**: node authentication, admin permissions, and no shell commands from templates.
- **Supported systems**: Ubuntu 22.04, 24.04 and 26.04, and Docker.
- Docker support:  install via : bash <(curl https://i.hiddify.com/docker/beta)
- Direct installation:  bash <(curl https://i.hiddify.com/beta)

> ⚠️ **Before upgrading**: take a full backup, and see [section 2](#2-breaking-changes--upgrade-notes-read-before-upgrading).

---

## Highlights

### Proxy engine
- **New proxy management engine.** It ships with 218 built-in proxies covering many combinations of protocol, transport and security. Every detail of every proxy can be edited, and any change can be reverted to the built-in default.
- **Shared settings are edited in one place.** Common parts live in shared templates and base configs, so a change applies to every proxy that uses them.
- **Per-domain proxy selection.** Each domain can choose which proxies it serves.
- **Xray and sing-box (Hiddify Core) proxies work side by side.** For protocols both cores support, you choose which core serves them.
- **Split XHTTP upload and download.** Each direction can use its own TLS layer (HTTP, TLS, TLS H2, QUIC) and its own domain type (CDN, relay, REALITY, direct).
- **Latest Xray features.** This includes VLESS encryption, the Vision flow and automatic detection of when `insecure` is needed.
- **Ports 443 and 80 whenever possible.** Where possible, every proxy is served on the standard ports, and active probing by the GFW sees only a normal website.
- **High-performance QUIC and 50% faster TLS termination**, using HAProxy 3.4 (AWS-LC) and the new rust-rpxy-l4 SNI multiplexer.
- **Three DNS tunnels at once.** VayDNS, Slipstream and MasterDnsVPN can run together, sharing port 53.
- **New protocols**: AnyTLS, Snell, SOCKS and raw HTTP transport. Mieru has TCP and UDP variants, and REALITY works over TCP, HTTP, gRPC and XHTTP.

### Multi-node
- **Nodes keep working on their own if the connection to the central panel fails**, and they sync again once it comes back.
- **The central panel decides which nodes' domains appear in user subscriptions.**
- **The central dashboard shows health for every node**: CPU, RAM, disk, traffic, connections, version and online status.

### Admin experience
- **New interactive admin panel.** It includes a live dashboard with usage and user trends per node, a visual proxy, template and base-config editor with validation and preview, and example-config generation.
- **Utils page**, which runs in the browser only: a share-link decoder and editor (vless, vmess, ss, trojan and base64 subscriptions) and Base64/URL encoders.
- **Full Persian support** (RTL layout and the Vazirmatn font), plus dark mode and a mobile-friendly layout.

### Platform
- **Everything important lives in `/opt/hiddify-manager/data`**, so backing up that one folder is enough.
- **About 50% less panel memory.** Celery was replaced by an in-process scheduler, the panel runs on Granian, and heavy libraries load lazily.
- **Ubuntu 22.04, 24.04 and 26.04 are supported**, and Docker deployment is supported.
- **New `hiddify` command** for install, apply, update, status, admin links and password reset.
- **Faster, safer installer.** Steps run in parallel, locks no longer get stuck, and restarting the panel no longer interrupts an apply or install that is in progress.
- **Security fixes**: a node-authentication bypass and an admin privilege-escalation path were closed. Proxy templates can no longer run shell commands.

### Before you upgrade
Take a full backup. v13 moves the server to a new folder layout and moves the MySQL data into `data/mysql`. Custom v12 config templates are not carried over, and parent and child panels must be upgraded together. See [section 2](#2-breaking-changes--upgrade-notes-read-before-upgrading) for the full list.

---

## About this document

It covers every commit from **v12.3.3** to **v13.0.0b11** in both repositories:
- **hiddify-manager**: installer, services and infrastructure. 55 commits.
- **hiddify-panel** (`services/panel/src`): backend and admin UI. 110 commits.

Release-only commits are excluded. The sections below are ordered by importance, most important first.

---

## 1. Fully configurable proxy engine (proxy_v3)

**This is the core change of v13.**

In v12, proxies were a fixed matrix (protocol × transport × CDN) that hard-coded Python generators turned into configs. You could toggle proxies on and off, but you could not change what was generated.

In v13 every server inbound and every client outbound is a **Jinja template stored in the database**, and admins can edit them.

- **Custom proxies**: new `custom_proxy` table. A custom proxy combines:
  - protocol, transport and TLS layer;
  - domain modes;
  - server core and inbound template;
  - one outbound template per client core.
- **Modes** decide what a proxy binds to:
  - Domain gateways: `domains_l7_gateway`, `domains_sni_gateway`, `domains_dns_gateway`.
  - Public ports: `domains_auto_public_ports`, `domains_single_public_port`.
  - `ip`: bound to server IPs.
  - `no_inbound`: client-only; it has no server inbound and no domain binding.
- **Templates and base configs**: reusable fragments in the new `proxy_template` table, plus full base configs per core and side in `proxy_base_config`. Server base configs exist for xray, hiddify-core, haproxy, nginx, rust-rpxy-l4 and dns_proxy. Client base configs exist for xray, sing-box, hiddify-core, sublink and clash.
- **Built-in catalog with overrides**:
  - About 218 template files ship in `proxy_v3/proxy_templates/` and are synced into the database on start.
  - Built-in items keep their original content next to the admin's version, so any override can be **reverted to the catalog default**.
  - Built-in custom proxies are generated automatically from the proxy matrix.
- **Common proxies**: a protocol available on both Xray and Hiddify Core is flagged "common". The new `common_proxy_core` setting (xray, hiddify_core or both) picks which one runs.
- **Rendering**:
  - Each child panel has its own Jinja environment with caching.
  - Helpers include `skip()`, `include_path`, `download` (cached, with a 3-minute negative cache), `get_nodes_configs` and JSON/base64 filters.
  - A validation layer reports errors with their location. It is about 4,200 lines.
  - Commit cb0871eca fixed a bug where caches were never invalidated after an edit, so subscriptions stayed stale for 10–20 minutes.
- **Extra params**: domains and users get `extra_params`, stored as JSON5 and available inside templates (638c501d2).

Key commits: e5149dda7, d7ea4ed64, 9ac14933a, 6c9d9887f, 0a7d669a8, 28e619dd8, cb0871eca, 92b0af37c.

---

## 2. Breaking changes & upgrade notes (read before upgrading)

- **New on-disk layout**:
  - Code moved into `scripts/` and `services/`, and all persistent state moved into `data/`: SSL, logs, locks, MySQL, Redis, acme.sh state, `app.cfg` and `packages.db`.
  - `scripts/migrate_layout.sh` runs from the installer. It moves the v12 folders (`nginx`, `haproxy`, `singbox`, `xray`, `hiddify-panel`, `other`, …) into `/opt/hiddify-manager/old/`, and keeps the MySQL and Redis passwords.
  - **External scripts that call old paths will break**: `/opt/hiddify-manager/install.sh`, `common/utils.sh`, `hiddify-panel/`, `other/…`, `log/system`.
- **Server config templates removed from the manager repo**:
  - The xray, sing-box, HAProxy, nginx and rpxy templates are gone. The panel now generates these configs into `/opt/hiddify-manager/generated/`, through `hiddify-panel-cli dump-server-configs` or the `admin/dump-server-configs` API.
  - **Local edits to v12 templates are not carried over.** Customize through the new template editor instead.
- **MySQL moved to a dedicated service**:
  - The new `hiddify-mysql.service` runs its own MariaDB instance on `127.0.0.1:3306`, with its config in `data/mysql/my.cnf`.
  - The existing datadir is **moved from `/var/lib/mysql` to `data/mysql/db`**, keeping a `.bak.<timestamp>` copy when it has to rsync. The distro `/etc/mysql` config is no longer used.
  - **Take a backup before upgrading.**
- **systemd unit changes**:
  - `hiddify-singbox` is now `hiddify-core`.
  - `hiddify-panel-background-tasks` (Celery) is removed; it is disabled and deleted on upgrade.
  - New units: `hiddify-mysql`, `hiddify-rpxy-l4`, `hiddify-{dnstt,slipstream,masterdns}@<domain>`, `hiddify-dnstm-router`.
- **Database migrations**:
  - `MAX_DB_VERSION` goes from 130 to 144.
  - Legacy domain types are **remapped in place** before the ENUM shrinks:

    | v12 domain type | becomes |
    |---|---|
    | `auto_cdn_ip` | `cdn` with resolve_ip |
    | `fake` | `direct` + FakeMode `fake` |
    | `reality`, `special_reality_*` | `direct` + FakeMode `reality` |
    | `dnstt` | `direct` + FakeMode `dns` |
    | `old_xtls_direct` | `direct` |

  - `proxy.proto` `ss` becomes `shadowsocks`, and `user.mode` `disable` becomes `no_reset`.
  - `domain.sub_link_only` is dropped; it is now a domain mode.
- **Hidden or replaced settings**:
  - `core_type` is replaced by `common_proxy_core`.
  - `additional_configs_*` is replaced by additional-config templates.
  - `path_*` settings are hidden.
  - `parent_domain` and `parent_admin_proxy_path` are deprecated.
- **Runtime requirements**: the panel needs **Python ≥ 3.13**. Celery, bjoern and marshmallow were removed as direct dependencies, and APScheduler 3.x was added.
- **Component changes**:
  - HAProxy is now **3.4 `haproxy-awslc`** from the haproxy.com repository; the Ubuntu 22.04 special case was removed.
  - nginx is **1.30**.
  - Ubuntu 22.04 or newer is required.
- **Upgrade parent and child panels together.** The parent `usage` API now returns a structured response, and node authentication changed.
- **Removed services**: SSH (ssh-liberty-bridge) moved to `services/deprecated` and is no longer installed. ShadowTLS is removed.

---

## 3. Protocols, transports and cores

- **New protocols**: AnyTLS, Snell, SOCKS, **Slipstream** and **MasterDNS**, all new in `ProxyProto`. Mieru has TCP and UDP variants.
- **DNS tunnels rebuilt** (`services/dns_proxy`, replaces `other/dnstt`):
  - One systemd instance per domain.
  - The "dnstt" protocol is now served by **VayDNS**. **Slipstream** 0.1.1 and **MasterDnsVPN** were added.
  - **dnstm** routes several tunnels on port 53.
  - The whole group is still switched on and off with `dnstt_enable`.
- **VLESS improvements**: VLESS **encryption/decryption** and the **`xtls-rprx-vision` flow** are supported; they are only emitted for the Xray core. There are plain-HTTP (no TLS) VLESS/VMess variants, and REALITY now works over TCP, raw HTTP, gRPC and xHTTP-H2.
- **Transports**:
  - Raw **HTTP** (TCP HTTP obfuscation) is new.
  - **xHTTP** has upload and download ALPN variants (HTTP, TLS H1, TLS H2, QUIC), with separate download settings.
- **Scale**:
  - The protocol matrix now has 143 combinations, 129 of them on by default, grouped into 64 preset slots.
  - A commit message says roughly 80 protocols were tested end to end (e8d088c12).
  - Preset slots per protocol: VLESS 27, VMess 14, Trojan 5, plus Shadowsocks, SS2022, ShadowTLS, Naive, Mieru, TUIC, Hysteria, Hysteria2, WireGuard, SS-FakeTLS, v2ray and SSH.
- **Cores**:
  - Server cores: **hiddify-core** (sing-box based), **rust-rpxy-l4** (an L4 TLS/QUIC SNI multiplexer) and **dns_proxy**, alongside xray, haproxy and nginx.
  - Client cores: sublink, xray, sing-box, **hiddify-core** and clash. xHTTP is disabled for sing-box.

Key commits: 83e512d1f, acb69a0d4, 3405123b7, e8d088c12, d71977ba9; manager repo: 7b602e9, 10d967a, 1aa6241.

---

## 4. Multi-node (parent / child panels)

- **Nodes keep working offline**: a node keeps serving its users with its last synced state when it cannot reach the parent. Usage and changes are exchanged again once the connection comes back.
- **The parent chooses node domains**: the parent decides which child domains' proxies go into each user's subscription, and requests those configs from the child for that exact list of domains.
- **Child registration**: a child's registration stores its `node_base_url`, and re-registering updates its name and URL. A child that has the parent's own unique ID is rejected. Sync requests go to the node's base URL instead of the first panel domain.
- **Get configs from child**:
  - New endpoint `/api/v2/child/client-configs/`, protected by node auth.
  - A parent can pull per-node client configs and merge them into the user's subscription, for xray, clash, sublink and hiddify-core.
  - Failed fetches are cached for 3 minutes so a dead node does not slow every subscription request down.
- **Node status**: parent and node exchange "last contact" timestamps in both directions, shown in the node list.
- **Metrics**: the parent pulls each node's metrics with its API key and a 30-second timeout, and errors are isolated per node.
- **Other**:
  - Bulk registration now covers server IPs, the TLS store, custom proxies and proxies.
  - `?debug_node=1` simulates three fake nodes for testing the multi-node dashboard.

Key commits: ef0dc66f2, 3d8d919c4, b2c986037, 31290230e, f4ae50870, f02081b17, d5e0c76ab, e829fb623.

---

## 5. New admin panel (Admin V2) and dashboard

**New app:** a Vue 3 + PrimeVue app served at `/<proxy_path>/admin/v2/`, for super admins only. **It is now the default landing page after login.**

**Integration with the legacy panel:**
- The legacy menu and warnings appear inside V2.
- Users, admins, domains, settings and backup still open the legacy pages.

**Dashboard** (new):
- Usage tiles for today, week, month and total, with trend comparisons.
- Usage and online-user trend charts, stacked per node.
- Online, enabled and total user counts.
- **Node health** for each node:
  - CPU per core, RAM, swap, disk, load average and uptime;
  - live network traffic and connections;
  - top processes and largest folders;
  - panel version and online status.

**Proxy editor**:
- List with search, filters and inline enable toggles.
- Full editor with General, Server and Client tabs, per-field "Override" on built-in presets, validation, preview and "Generate example" for a chosen user, domain, IP and user agent.
- Bundle export and import.
- "Generate all configs" renders the server and client configs for any selection.

**Templates, Base Configs and Template Variables**:
- JSON5 and Jinja editors with variable insertion and preview.
- A browsable catalogue of the variables available to templates.

**Utils** (runs in the browser only): share-link decoder and editor (vless/vmess/ss/trojan, base64 subscriptions), plus Base64 and URL encoders.

**UX**:
- System actions (apply, update, reinstall, reset) are POST requests with a red confirmation dialog.
- Dark mode, responsive layout, and full **Persian translation with RTL and the Vazirmatn font**.
- Only English and Persian have V2 translations; the other languages fall back to English.

Key commits: e5149dda7, 84c054f10, bfc2a5786, 13ef8c9e3, 92b0af37c, 0582f2a96, 00323926f, b6fa06c6c.

---

## 6. Performance and memory

- **Celery replaced by APScheduler** running inside the panel process:
  - `update_usage` runs every 60 seconds and the backup runs every 6 hours.
  - Redis locks prevent two workers from running the same job.
  - This removes a whole service and a large part of the memory footprint.
- **Panel server**: the panel now runs under **Granian** on port 9000 (10 threads, worker memory capped at 500 MB, `MALLOC_ARENA_MAX=2`).
- **Lighter imports**: xtlsapi is loaded only when needed, and the CLI no longer imports the web stack.
- **Faster first setup**: the REALITY-friendly domain search no longer runs up to 450 network probes, so the initial setup doesn't hang on restricted networks or in Docker.
- **Apply Config** no longer flushes Redis and Jinja caches, which used to restart and kill the panel mid-run.

Key commits: f219b2179, e2b5d3fb0, e967d269d, 5db33be44; manager repo: 44c2390, 2253ad4.

---

## 7. Installer, operations and infrastructure

- **New `hiddify` CLI** (`/usr/bin/hiddify`, with bash completion). Commands: `install`, `apply`, `update`, `start`, `stop`, `restart`, `status`, `sync-configs`, `admin` (prints the admin links), `reset-password` and `uninstall`.
- **Apply and install run in their own systemd unit**, so restarting the panel no longer kills them halfway through (27ca4cf).
- **flock-based locking**: locks are released automatically when the process dies, so stale lock files no longer block installs (33507f4).
- **Faster installer**:
  - More steps run in parallel.
  - Each step logs how long it took.
  - Error codes are propagated.
- **Docker**:
  - Ubuntu 24.04 image.
  - Separate MariaDB and Redis containers with healthchecks.
  - Host networking.
  - `docker-init.sh` checks the required environment variables.
- **Certificates**:
  - acme.sh registers with Let's Encrypt and ZeroSSL using a real email.
  - Certificates are synced into the panel's new TLS store, which validates subject alternative names and hostnames.
- **Version bumps**: nginx 1.30, HAProxy 3.4 (aws-lc), WARP (wgcf) 2.2.31, and telemt 3.3.31 added to the package lock.
- **Other**:
  - Ubuntu 26 sudo fix.
  - `download.sh` accepts `develop` as an alias of `dev`.

---

## 8. Subscriptions and client output

- **One renderer for every endpoint**: `/sub`, `/sub64`, `/xray`, `/singbox`, `/clash`, `/clashmeta`, `/full-singbox.json`, `/all.txt`, `/wireguard` and `/auto` all go through the new engine.
- **Automatic core selection**: `/auto` picks hiddify-core, sing-box, xray or sublink from the User-Agent.
- **Xray JSON** is an array of full configs with a proxy group and fragment support.
- **Render errors are visible**: a failed render returns a readable error config instead of an empty response (e87b638d7).
- **Multiple IPs**:
  - Outbound tags now label IPv4 and IPv6 endpoints.
  - `max_proxy_ips_per_version` defaults to 3.
- **Fixes**:
  - TB usage no longer shows in scientific notation in subscription remarks.
  - `encryption=none` is set for non-Xray cores.
  - sing-box `domain_strategy` is restored for older clients.
  - WireGuard uses `endpoints` on sing-box 1.11 and later.
- **New templates**: `subscription_status`, `additional_config` and `node_configs`.

---

## 9. Domains, TLS, REALITY and CDN

- **New domain model**:
  - `DomainType` is now direct, sub_link_only, cdn, relay or worker.
  - A new **FakeMode** column (valid, fake, reality, dns) combines with it into domain modes: `direct-valid`, `direct-fake`, `direct-reality`, `direct-dns`, `relay-*` and `cdn`.
  - A domain can select **several proxies**.
- **New domain fields**:
  - `server_domain`: use another domain as the client's server address.
  - An **ECH** flag.
  - `extra_params`.
- **REALITY**: clients are built from the L7 REALITY proxies instead of a pinned termination proxy.
- **CDN**: clients pin the CDN edge certificate, and direct and REALITY clients prefer a stable server IP, IPv4 first.
- **HAProxy templates** gained DNS resolvers and a decoy upstream.
- **Domain entry**: better domain detection, whitespace is stripped, and there is a domain creation template.

---

## 10. Security

- **Node authentication bypass fixed**: when both `roles` and `node_auth` were set, the check could let a request through incorrectly. Parent registration is protected again, and a node can only register itself (e690e4113).
- **Admin privilege escalation blocked**:
  - Admins cannot grant a higher role than their own, or change their own role or `can_add_admin`.
  - Only a super admin can create super admins.
  - Admins who are not super admins always become the parent of the admins they create (6bb68a00e).
- **User limits**: creating a user through the API now enforces the admin's `max_users` and `max_active_users`.
- **MySQL hardening**: MySQL listens on localhost only, runs with systemd hardening and AppArmor, and the panel database user is re-synced on every install.
- **No shell commands from templates**: the Jinja `exec` helper, which ran shell commands, was removed.
  - The two built-in templates that used it now use `panel_static_dir`, `now()` and `timedelta`.
  - Previously, editing a template was equivalent to running commands as root on the server.
  - As a side effect, the quick-setup link no longer breaks after 23:00.

---

## 11. API changes (for API consumers)

- **Schema migration**: v2 API schemas moved from marshmallow to **pydantic**. Unknown fields are ignored, and validation error formats may differ.
- **New super-admin endpoints**:
  - `GET /api/v2/admin/dump-server-configs/`
  - `GET /api/v2/admin/sync-tls-store/`
  - The full proxy_v3 REST API: custom proxies, templates, base configs, variables, validation, preview and bundles.
- **Removed**: v1 `DELETE` on the user resource.
- **Changed**: the parent `usage` endpoint returns a structured `UsageResponseSchema`.

---

## 12. Backup, restore and data integrity

- **Backup and restore rebuilt** on typed "external models":
  - Unknown keys are ignored.
  - A partial update only touches the fields it sends.
  - Errors are readable.
  - Automatic backups go to `data/backup`.
- **Package end-date fix**: end dates were computed as a number in MySQL (for example 20260801 + 90 = 20260891), which gave wrong expiry and reset decisions. The calculation now uses `ADDDATE` (ed9dcd935).
- **Typed models**: SQLAlchemy 2 typed models across 13 tables.
- **Admin timestamps**: `AdminUser` gets `last_online` and `last_modified_time`, so parent sync can detect admin changes.
- **Settings race**: `set_hconfig` recovers from an insert race.


