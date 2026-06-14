"""
Self-update the hiddify-manager repo from GitHub.

Replaces common/hiddify_installer.sh::update_from_github + update_config.
Picks the right tarball/zip per release mode, downloads it, extracts
into /opt/hiddify-manager (overwriting on top of the running install),
clears the cached rendered configs that the legacy script also wiped,
and writes the new VERSION file.

The orchestrator caller is expected to re-invoke ./init.sh install
after this completes — we deliberately don't os.execv to avoid being
surprising about it.
"""
import glob
import os
import shutil
import sys
import tarfile
import tempfile
import urllib.request
import zipfile

from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT


GITHUB_RELEASE_LATEST = (
    "https://github.com/hiddify/Hiddify-Manager/releases/latest/download/hiddify-manager.zip"
)
GITHUB_RELEASE_TAG = (
    "https://github.com/hiddify/Hiddify-Manager/releases/download/{tag}/hiddify-manager.zip"
)
GITHUB_DEV_TARBALL = (
    "https://github.com/hiddify/hiddify-manager/archive/refs/heads/dev.tar.gz"
)

# Per the legacy script: stale rendered configs that must be wiped before
# the new install renders them fresh. Globs against PROJECT_ROOT.
STALE_CONFIG_GLOBS = [
    "xray/configs/*.json",
    "singbox/configs/*.json",
    "xray/configs/05_inbounds_10*.json*",
    "xray/configs/05_inbounds_h2*.json*",
    "xray/configs/05_inbounds_02_realitygrpc*.json*",
    "xray/configs/05_inbounds_02_realityh2*.json*",
    "singbox/configs/05_inbounds_2071_realitygrpc_main.json*",
    "singbox/configs/05_inbounds_20[123][1234]*.json*",
]


def url_for_mode(mode):
    """Map a release mode to the matching archive URL. Returns None for modes
    that don't pull from GitHub (e.g. docker uses local src)."""
    mode = (mode or "release").lower()
    if mode == "release":
        return GITHUB_RELEASE_LATEST
    if mode.startswith("v"):
        return GITHUB_RELEASE_TAG.format(tag=mode)
    if mode in ("dev", "develop"):
        return GITHUB_DEV_TARBALL
    if mode == "beta":
        # Beta uses a tagged release; without a known tag we can't pick
        # the URL. Caller should resolve the tag via the GitHub API and
        # pass it as `v<tag>` instead.
        log.warning("manager_updater: beta mode needs an explicit v<tag>; skipping source update")
        return None
    if mode == "docker":
        return None
    log.error(f"manager_updater: unknown mode {mode!r}")
    return None


def _download(url, dest):
    log.info(f"manager_updater: downloading {url}")
    urllib.request.urlretrieve(url, dest)


def _extract(archive_path, dest_dir):
    """
    Extract a .zip or .tar.gz into dest_dir. For tar.gz we strip the top-
    level GitHub directory (so the archive contents land directly under
    dest_dir, matching legacy `tar --strip-components=1` behaviour).
    """
    if archive_path.endswith(".zip"):
        with zipfile.ZipFile(archive_path) as zf:
            zf.extractall(dest_dir)
    elif archive_path.endswith((".tar.gz", ".tgz")):
        with tarfile.open(archive_path, "r:gz") as tf:
            # GitHub tarballs wrap everything in `Hiddify-Manager-<ref>/`.
            members = []
            for m in tf.getmembers():
                parts = m.name.split("/", 1)
                if len(parts) < 2:
                    continue
                m.name = parts[1]
                members.append(m)
            # filter="data" mirrors the safe-extraction policy Python 3.14
            # will default to. Avoids the DeprecationWarning on 3.12+ and is
            # the right behaviour for unzipping into a real directory.
            tf.extractall(dest_dir, members=members, filter="data")
    else:
        raise ValueError(f"unsupported archive format: {archive_path}")


def _wipe_stale_configs():
    for pattern in STALE_CONFIG_GLOBS:
        for path in glob.glob(os.path.join(PROJECT_ROOT, pattern)):
            try:
                os.remove(path)
            except OSError as e:
                log.warning(f"manager_updater: could not remove {path}: {e}")


def _merge_into_project(staging_dir):
    """
    Copy everything under staging_dir on top of PROJECT_ROOT. We use
    shutil.copytree with dirs_exist_ok=True instead of mv-ing, because the
    current python process has files under PROJECT_ROOT open and a wholesale
    rename would invalidate them.
    """
    for entry in os.listdir(staging_dir):
        src = os.path.join(staging_dir, entry)
        dst = os.path.join(PROJECT_ROOT, entry)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)


def update_manager_source(mode, override_version=None):
    """
    Download + extract a fresh hiddify-manager release on top of the
    running install. Returns True on success, False otherwise (including
    when the mode is one we don't fetch source for).
    """
    url = url_for_mode(mode)
    if not url:
        return False

    suffix = ".tar.gz" if url.endswith(".tar.gz") else ".zip"
    with tempfile.TemporaryDirectory() as tmp:
        archive = os.path.join(tmp, f"hiddify-manager{suffix}")
        staging = os.path.join(tmp, "extracted")
        os.makedirs(staging, exist_ok=True)
        try:
            _download(url, archive)
            _extract(archive, staging)
        except Exception as e:
            log.error(f"manager_updater: download/extract failed: {e}")
            return False

        os.makedirs(PROJECT_ROOT, exist_ok=True)
        _merge_into_project(staging)

    if override_version:
        try:
            with open(os.path.join(PROJECT_ROOT, "VERSION"), "w") as f:
                f.write(override_version + "\n")
        except OSError as e:
            log.warning(f"manager_updater: could not write VERSION: {e}")

    _wipe_stale_configs()
    log.info("manager_updater: source updated. Re-run ./init.sh install to apply.")
    return True


def main():
    if len(sys.argv) < 2:
        print("usage: manager_updater <release|beta|dev|develop|v<tag>>")
        return 2
    mode = sys.argv[1]
    ok = update_manager_source(mode)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
