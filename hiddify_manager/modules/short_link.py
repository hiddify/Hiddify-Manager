"""
Temporary nginx short-link injector.

Replaces nginx/add2shortlink.sh: appends a `location` block to
nginx/parts/short-link.conf that 302-redirects a short slug to a real
URL, then schedules its removal via `at(1)` after N minutes, and asks
nginx to reload.

Invoked from the panel through common/commander.py.
"""
import os
import re
import sys

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT
from hiddify_manager.utils.shell import run_cmd


SHORT_LINK_CONF = os.path.join(PROJECT_ROOT, "nginx", "parts", "short-link.conf")
NGINX_UNIT = "hiddify-nginx.service"

_SLUG_RE = re.compile(r"^[a-zA-Z0-9_-]+$")


def add(real_url, slug, minutes):
    """
    Add a short-link entry and schedule its removal.

    Returns 0 on success, non-zero on validation failure.
    """
    if not slug or not _SLUG_RE.fullmatch(slug):
        log.error(f"short_link: refusing invalid slug {slug!r}")
        return 1
    try:
        minutes = int(minutes)
    except (TypeError, ValueError):
        log.error(f"short_link: invalid minutes value {minutes!r}")
        return 2
    if minutes <= 0:
        log.error(f"short_link: minutes must be positive, got {minutes}")
        return 3

    # Append the nginx location block.
    block = f"location ~* ^/{slug}(/)?$ {{return 302 {real_url};}}\n"
    os.makedirs(os.path.dirname(SHORT_LINK_CONF), exist_ok=True)
    with open(SHORT_LINK_CONF, "a") as f:
        f.write(block)
    log.info(f"short_link: added {slug} -> {real_url} for {minutes}m")

    # Schedule the removal via at(1). The sed command strips any line
    # mentioning the slug; the original used the same approach.
    sed_cmd = f"sed -i '/\\/{slug}(/d' {SHORT_LINK_CONF}"
    run_cmd(
        ["at", "now", f"+{minutes}", "minutes"],
        check=False, input_data=sed_cmd + "\n",
    )

    run_cmd(["systemctl", "reload", NGINX_UNIT], check=False)
    return 0


def main():
    """CLI: short_link <real_url> <slug> <minutes>."""
    if len(sys.argv) < 4:
        print("usage: short_link <real_url> <slug> <minutes>")
        return 2
    return add(sys.argv[1], sys.argv[2], sys.argv[3])


if __name__ == "__main__":
    sys.exit(main())
