"""
Cron'd nightly maintenance tasks.

Replaces common/daily_actions.sh. The legacy script `bash`'d into
acme.sh/run.sh — which no longer exists, so the nightly job has been
silently broken since the cert flow moved to python. We restore the
intended behaviour: walk every domain in current.json and refresh
its cert via modules.cert_issuer.get_cert (which knows how to fall
back to self-signed when ACME isn't reachable).

Invoked by the /etc/cron.d/hiddify_daily entry written from
modules.common.apply_runtime_config.
"""
import sys

from hiddify_manager.modules.cert_issuer import get_cert
from hiddify_manager.utils.config import hiddify_config
from hiddify_manager.utils.logger import log


def run():
    configs = hiddify_config() or {}
    domains = configs.get("domains") or []
    if not domains:
        log.info("daily_actions: no domains in current.json — nothing to do")
        return 0

    for entry in domains:
        domain = (entry or {}).get("domain") if isinstance(entry, dict) else None
        if not domain:
            continue
        log.info(f"daily_actions: refreshing cert for {domain}")
        get_cert(domain)
    return 0


def main():
    return run()


if __name__ == "__main__":
    sys.exit(main())
