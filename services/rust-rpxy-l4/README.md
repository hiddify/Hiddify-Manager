# rust-rpxy-l4 (SNI proxy)

L4 TLS/QUIC multiplexer used to route incoming connections to different local proxy ports based on SNI.

## Layout

```
other/rust-rpxy-l4/
  bin/rpxy-l4          # binary (from GitHub release)
  config.toml.j2       # rendered by common/jinja.py → config.toml
  install.sh           # download + install binary
  run.sh               # enable systemd service
  disable.sh           # stop/disable service
```

## SNI routing

`config.toml.j2` mirrors `haproxy/maps/sni.j2`:

| SNI | Backend |
|-----|---------|
| domains with `internal_port_special` | `127.0.0.1:<port>` (REALITY / special inbounds) |
| `ssfaketls_fakedomain` | `127.0.0.1:1010` |
| `telegram_fakedomain` | `127.0.0.1:1001` |
| `shadowtls_fakedomain` | `127.0.0.1:1030` |
| `old_xtls_direct` domains | `127.0.0.1:445` (or `rpxy_l4_xray_force_port`) |

All TCP backends use PROXY protocol v2 (`send-proxy-v2`), matching HAProxy backends.

## Port 443 note

HAProxy also binds `:443` for `https-in`. Enable **either** HAProxy SNI frontend **or** rpxy-l4 on 443, not both.

Install is wired in `install.sh` with `rpxy_l4_enable` (disabled by default). When enabling:

1. Set `rpxy_l4_enable` in panel config
2. Optionally set `rpxy_l4_default_port` for unmatched SNI (HAProxy SSL terminator on localhost)
3. Disable HAProxy `:443` SNI bind or move it behind rpxy-l4

## Package versions

```bash
bash add_version.sh   # registers 0.2.3 in common/packages.lock
bash install.sh
bash run.sh
```
