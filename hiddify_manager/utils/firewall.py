"""
Idempotent iptables/ip6tables helpers used by the post-panel system
configuration step.

Ports common/utils.sh's `add2iptables`, `allow_port`, `remove_port`, and
`save_firewall`. Every rule mutation goes through `add_rule` which checks
`iptables -C` first, so re-running install.sh is safe.
"""
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd

IPTABLES = "iptables"
IP6TABLES = "ip6tables"


def add_rule(rule, *, both=True):
    """
    Idempotently insert an iptables rule. `rule` is the argv tail after
    `iptables -I` / `iptables -C`, as a list — e.g.
        ["INPUT", "-p", "tcp", "--dport", "443", "-j", "ACCEPT"]

    When both=True (the default), apply to v4 and v6.
    """
    binaries = (IPTABLES, IP6TABLES) if both else (IPTABLES,)
    for ipt in binaries:
        # -C exits 0 if the rule already exists, non-zero otherwise.
        check = run_cmd([ipt, "-C", *rule], check=False, capture_output=True)
        if check.returncode == 0:
            continue
        run_cmd([ipt, "-I", *rule], check=False, capture_output=True)


def add_rule_v6_only(rule):
    """ip6tables-only variant for IPv6 ICMP and friends."""
    check = run_cmd([IP6TABLES, "-C", *rule], check=False, capture_output=True)
    if check.returncode == 0:
        return
    run_cmd([IP6TABLES, "-I", *rule], check=False, capture_output=True)


def allow_port(proto, port):
    """
    `allow_port("tcp", 443)` opens INPUT for that proto+port on v4 and v6,
    plus a conntrack NEW rule that matches the legacy allow_port helper.
    """
    port_str = str(port)
    add_rule(["INPUT", "-p", proto, "--dport", port_str, "-j", "ACCEPT"])
    add_rule([
        "INPUT", "-p", proto, "-m", proto, "--dport", port_str,
        "-m", "conntrack", "--ctstate", "NEW", "-j", "ACCEPT",
    ])


def remove_port(proto, port):
    """Best-effort delete of an allow_port rule on both v4 and v6."""
    port_str = str(port)
    for ipt in (IPTABLES, IP6TABLES):
        run_cmd(
            [ipt, "-D", "INPUT", "-p", proto, "--dport", port_str, "-j", "ACCEPT"],
            check=False, capture_output=True,
        )


def set_input_policy(policy):
    """policy must be 'ACCEPT' or 'DROP'. Applied to INPUT + FORWARD, v4+v6."""
    if policy not in ("ACCEPT", "DROP"):
        log.error(f"firewall: refusing to set unknown policy {policy!r}")
        return
    for ipt in (IPTABLES, IP6TABLES):
        for chain in ("INPUT", "FORWARD"):
            run_cmd([ipt, "-P", chain, policy], check=False, capture_output=True)


def save():
    """
    Equivalent to legacy save_firewall: dump current ruleset, dedupe lines
    (in-place), restore. We open the dump files with O_TRUNC via a normal
    write so the dedupe step doesn't race a half-written file.
    """
    import os
    os.makedirs("/etc/iptables", exist_ok=True)
    for ipt_save, ipt_restore, target in (
        ("iptables-save", "iptables-restore", "/etc/iptables/rules.v4"),
        ("ip6tables-save", "ip6tables-restore", "/etc/iptables/rules.v6"),
    ):
        dump = run_cmd([ipt_save], check=False, capture_output=True)
        if dump.returncode != 0:
            log.warning(f"firewall: {ipt_save} failed; skipping {target}")
            continue
        seen = set()
        deduped = []
        for line in (dump.stdout or "").splitlines():
            if line in seen:
                continue
            seen.add(line)
            deduped.append(line)
        deduped.append("COMMIT")  # matches the legacy `echo "COMMIT" >> ...`
        with open(target, "w") as f:
            f.write("\n".join(deduped) + "\n")
        # Apply the deduped ruleset.
        with open(target) as f:
            run_cmd([ipt_restore], check=False, input_data=f.read())
