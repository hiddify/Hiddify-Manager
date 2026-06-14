"""
Add/remove the Hiddify support team's SSH access for remote troubleshooting.

Replaces common/{add,remove}_remote_assistant.sh. The pubkey below is
the one the legacy scripts embedded verbatim — kept as a constant so
both add() and remove() can match by line content.
"""
import os

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.shell import run_cmd


HIDDIFY_ASSISTANT_KEY = (
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDWEXarp7YrTNX+4uNfdYtQ1lVsrD9/6oHaNiR6"
    "kgzoeShD/+3Ljou3veXofVstCb6CpFZdmOaKXNJyT5N+gm0eXwYJNsnrkCRq9h/6ydkoVdPAINz"
    "HZoetVqwqAPgmqzR8xTKZPP/Ky3Ks8OQEIg1Swnm9XXuP+ApmvOxGut9pPhOozKSATklojRaAmh"
    "dz4y9YpkLi94C1Ixd10Ewjld4pnVp4+uDTkXV2i3N3lH5x6zFrk2tefigoZ60brNWC3TGL3SjQ4"
    "obkD2qKpKqIRy63cUzfI0lP/0vZ7Ms5ESPlLI/ebMGvns9hINi1KRJ8m0//Jy0CDngJNJxG8KGb"
    "vqvLu/avmdVUHr48y7bk6VTGicMp16LfbszRQRF2d61n5uwBGXUB5DbVNI00yOdqAflDEloBEch"
    "qiWIEotBXyGTB1e2V1Oe95W27h9QSMbhNwmEk/QGPn4yhRgTbFq1TwNhE6DXZrCUbW8x4KVMQTS"
    "D+seUB0fMgTTXtzpPEo3mFAME= hiddify@assistant"
)


def _authorized_keys_path():
    return os.path.join(os.path.expanduser("~"), ".ssh", "authorized_keys")


def _public_ipv4():
    """Same v4.ident.me probe the legacy used to print the connection string."""
    res = run_cmd(
        ["curl", "--connect-timeout", "1", "-s", "https://v4.ident.me/"],
        check=False, capture_output=True,
    )
    return (res.stdout or "").strip()


def _ssh_listening_port():
    """
    Grep `ss -tulpn` for sshd's listen port — matches the legacy
    ss/grep/awk pipeline. Returns the first integer port or None.
    """
    res = run_cmd(["ss", "-tulpn"], check=False, capture_output=True)
    if res.returncode != 0:
        return None
    for line in (res.stdout or "").splitlines():
        if "sshd" not in line:
            continue
        # Local address is the 5th column (index 4) for ss -tulpn output.
        parts = line.split()
        if len(parts) < 5:
            continue
        addr = parts[4]
        if ":" not in addr:
            continue
        port_str = addr.rsplit(":", 1)[1]
        if port_str.isdigit():
            return int(port_str)
    return None


def add():
    """
    Append the assistant pubkey to ~/.ssh/authorized_keys (no dedup —
    matches legacy), then print the SSH command to send to support.
    Returns the path of the authorized_keys file.
    """
    auth = _authorized_keys_path()
    os.makedirs(os.path.dirname(auth), exist_ok=True)
    # Don't double-add — the bash version did, but that just creates
    # noise in the file. Cheap to guard.
    existing = ""
    if os.path.exists(auth):
        with open(auth) as f:
            existing = f.read()
    if HIDDIFY_ASSISTANT_KEY not in existing:
        with open(auth, "a") as f:
            if existing and not existing.endswith("\n"):
                f.write("\n")
            f.write(HIDDIFY_ASSISTANT_KEY + "\n")
    os.chmod(auth, 0o600)

    log.info("Now please send the following to https://t.me/hiddifybot")
    ip = _public_ipv4() or "<server-ip>"
    user = os.environ.get("USER") or "root"
    port = _ssh_listening_port()
    if port:
        log.info(f"ssh {user}@{ip} -p {port}")
    else:
        log.info(f"ssh {user}@{ip}")
    return auth


def remove():
    """Drop the assistant pubkey line from ~/.ssh/authorized_keys."""
    auth = _authorized_keys_path()
    if not os.path.exists(auth):
        log.info("remote_assistant: no authorized_keys file — nothing to remove")
        return
    with open(auth) as f:
        kept = [ln for ln in f.readlines() if HIDDIFY_ASSISTANT_KEY not in ln]
    with open(auth, "w") as f:
        f.writelines(kept)
    os.chmod(auth, 0o600)
    log.info("remote assistant access is removed")
