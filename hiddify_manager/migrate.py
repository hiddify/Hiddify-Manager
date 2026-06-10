"""
Migration tool for Hiddify-Manager.

Migrates data from a legacy Hiddify installation to the new Python-based setup.
This is designed to be run once after a fresh installation to import
configuration and user data from a previous installation.
"""
import os
import sys
import shutil
import glob
from hiddify_manager.utils.logger import log
from hiddify_manager.utils.paths import PROJECT_ROOT

# Default legacy installation path
LEGACY_DIR = "/opt/hiddify-manager"


def find_legacy_installation():
    """Locate the legacy installation directory."""
    candidates = [
        LEGACY_DIR,
        "/opt/hiddify-server",
        "/opt/hiddify-config",
    ]
    for path in candidates:
        if os.path.isdir(path) and os.path.realpath(path) != os.path.realpath(PROJECT_ROOT):
            return path
    return None


def migrate_database(legacy_dir: str, dry_run: bool = False):
    """Copy hiddify-panel.db from the legacy installation."""
    db_candidates = [
        os.path.join(legacy_dir, "hiddify-panel", "hiddifypanel.db"),
        os.path.join(legacy_dir, "hiddify-panel", "hiddify-panel.db"),
    ]
    target_dir = os.path.join(PROJECT_ROOT, "hiddify-panel")
    os.makedirs(target_dir, exist_ok=True)

    for db_path in db_candidates:
        if os.path.isfile(db_path):
            target = os.path.join(target_dir, os.path.basename(db_path))
            if dry_run:
                log.info(f"[DRY RUN] Would copy {db_path} -> {target}")
            else:
                shutil.copy2(db_path, target)
                log.info(f"Migrated database: {db_path} -> {target}")
            return True

    log.warning("No legacy database found to migrate.")
    return False


def migrate_ssl_certs(legacy_dir: str, dry_run: bool = False):
    """Copy SSL certificates from the legacy installation."""
    legacy_ssl = os.path.join(legacy_dir, "ssl")
    target_ssl = os.path.join(PROJECT_ROOT, "ssl")

    if not os.path.isdir(legacy_ssl):
        log.info("No legacy SSL directory found, skipping.")
        return False

    if dry_run:
        log.info(f"[DRY RUN] Would copy {legacy_ssl} -> {target_ssl}")
    else:
        if os.path.exists(target_ssl):
            shutil.rmtree(target_ssl)
        shutil.copytree(legacy_ssl, target_ssl)
        log.info(f"Migrated SSL certs: {legacy_ssl} -> {target_ssl}")
    return True


def migrate_acme_data(legacy_dir: str, dry_run: bool = False):
    """Copy acme.sh data (certificates, account keys) from the legacy installation."""
    legacy_acme = os.path.join(legacy_dir, "acme.sh", "lib")
    target_acme = os.path.join(PROJECT_ROOT, "acme.sh", "lib")

    if not os.path.isdir(legacy_acme):
        log.info("No legacy acme.sh data found, skipping.")
        return False

    if dry_run:
        log.info(f"[DRY RUN] Would copy {legacy_acme} -> {target_acme}")
    else:
        if os.path.exists(target_acme):
            shutil.rmtree(target_acme)
        shutil.copytree(legacy_acme, target_acme)
        log.info(f"Migrated acme.sh data: {legacy_acme} -> {target_acme}")
    return True


def migrate_config_env(legacy_dir: str, dry_run: bool = False):
    """Copy config.env from the legacy installation."""
    legacy_env = os.path.join(legacy_dir, "config.env")
    target_env = os.path.join(PROJECT_ROOT, "config.env")

    if not os.path.isfile(legacy_env):
        log.info("No legacy config.env found, skipping.")
        return False

    if dry_run:
        log.info(f"[DRY RUN] Would copy {legacy_env} -> {target_env}")
    else:
        shutil.copy2(legacy_env, target_env)
        log.info(f"Migrated config.env: {legacy_env} -> {target_env}")
    return True


def migrate_hiddify_data(legacy_dir: str, dry_run: bool = False):
    """Copy /hiddify-data/ if it exists (Docker setups)."""
    legacy_data = "/hiddify-data"
    if not os.path.isdir(legacy_data):
        log.info("No /hiddify-data directory found, skipping.")
        return False

    target_data = os.path.join(PROJECT_ROOT, "hiddify-data")
    if dry_run:
        log.info(f"[DRY RUN] Would copy {legacy_data} -> {target_data}")
    else:
        if not os.path.exists(target_data):
            shutil.copytree(legacy_data, target_data)
            log.info(f"Migrated hiddify-data: {legacy_data} -> {target_data}")
        else:
            log.info("hiddify-data already exists in the new installation, skipping.")
    return True


def run_migration(legacy_dir: str = None, dry_run: bool = False):
    """
    Run the full migration workflow.

    Args:
        legacy_dir: Path to legacy installation. Auto-detected if None.
        dry_run: If True, only log what would be done without making changes.
    """
    if legacy_dir is None:
        legacy_dir = find_legacy_installation()

    if legacy_dir is None:
        log.error("No legacy installation found. Nothing to migrate.")
        log.info("If your old installation is in a custom path, pass it explicitly:")
        log.info("  python3 -m hiddify_manager.migrate --legacy-dir /path/to/old/install")
        return False

    log.info(f"{'[DRY RUN] ' if dry_run else ''}Starting migration from: {legacy_dir}")
    log.info(f"Target installation: {PROJECT_ROOT}")
    log.info("=" * 60)

    results = {
        "database": migrate_database(legacy_dir, dry_run),
        "ssl_certs": migrate_ssl_certs(legacy_dir, dry_run),
        "acme_data": migrate_acme_data(legacy_dir, dry_run),
        "config_env": migrate_config_env(legacy_dir, dry_run),
        "hiddify_data": migrate_hiddify_data(legacy_dir, dry_run),
    }

    log.info("=" * 60)
    migrated = [k for k, v in results.items() if v]
    skipped = [k for k, v in results.items() if not v]

    if migrated:
        log.info(f"Successfully migrated: {', '.join(migrated)}")
    if skipped:
        log.info(f"Skipped (not found): {', '.join(skipped)}")

    return bool(migrated)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Migrate data from a legacy Hiddify installation")
    parser.add_argument("--legacy-dir", help="Path to the legacy installation directory")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be done without making changes")

    args = parser.parse_args()
    success = run_migration(legacy_dir=args.legacy_dir, dry_run=args.dry_run)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
