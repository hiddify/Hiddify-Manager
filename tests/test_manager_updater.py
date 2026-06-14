"""Tests for modules.manager_updater."""
import os
import tarfile
import zipfile
from unittest.mock import patch

import pytest

from hiddify_manager.modules import manager_updater as mu


# ---- url_for_mode ---------------------------------------------------------

def test_url_for_mode_release_returns_latest_zip():
    url = mu.url_for_mode("release")
    assert "releases/latest/download/hiddify-manager.zip" in url


def test_url_for_mode_tag_returns_tagged_zip():
    url = mu.url_for_mode("v10.20.3")
    assert "releases/download/v10.20.3/hiddify-manager.zip" in url


def test_url_for_mode_dev_returns_tar_gz():
    url = mu.url_for_mode("dev")
    assert url.endswith(".tar.gz")
    assert "refs/heads/dev" in url


def test_url_for_mode_develop_is_alias_for_dev():
    assert mu.url_for_mode("develop") == mu.url_for_mode("dev")


def test_url_for_mode_docker_returns_none():
    assert mu.url_for_mode("docker") is None


def test_url_for_mode_beta_requires_explicit_tag():
    """beta returns None — caller should resolve the tag and pass v<tag>."""
    assert mu.url_for_mode("beta") is None


def test_url_for_mode_unknown_returns_none():
    assert mu.url_for_mode("mystery") is None


# ---- _extract -------------------------------------------------------------

def test_extract_zip_drops_files_in_dest(tmp_path):
    archive = tmp_path / "x.zip"
    with zipfile.ZipFile(archive, "w") as zf:
        zf.writestr("README.md", "hello")
        zf.writestr("dir/file.txt", "content")
    dest = tmp_path / "out"
    dest.mkdir()
    mu._extract(str(archive), str(dest))
    assert (dest / "README.md").read_text() == "hello"
    assert (dest / "dir" / "file.txt").read_text() == "content"


def test_extract_tar_gz_strips_first_path_component(tmp_path):
    """GitHub-style tarballs wrap everything in Hiddify-Manager-<ref>/.
    _extract should peel that off so files land directly under dest."""
    archive = tmp_path / "x.tar.gz"
    with tarfile.open(archive, "w:gz") as tf:
        for name, body in [
            ("Hiddify-Manager-dev/README.md", "hello"),
            ("Hiddify-Manager-dev/dir/file.txt", "content"),
        ]:
            data = body.encode()
            info = tarfile.TarInfo(name=name)
            info.size = len(data)
            from io import BytesIO
            tf.addfile(info, BytesIO(data))
    dest = tmp_path / "out"
    dest.mkdir()
    mu._extract(str(archive), str(dest))
    assert (dest / "README.md").read_text() == "hello"
    assert (dest / "dir" / "file.txt").read_text() == "content"


def test_extract_unknown_format_raises(tmp_path):
    archive = tmp_path / "x.7z"
    archive.write_bytes(b"\x00")
    with pytest.raises(ValueError):
        mu._extract(str(archive), str(tmp_path / "out"))


# ---- _wipe_stale_configs --------------------------------------------------

def test_wipe_stale_configs_removes_matched_files(tmp_path, monkeypatch):
    """Files matching STALE_CONFIG_GLOBS get removed; others stay."""
    (tmp_path / "xray" / "configs").mkdir(parents=True)
    (tmp_path / "singbox" / "configs").mkdir(parents=True)
    # Will match xray/configs/*.json
    (tmp_path / "xray" / "configs" / "stale.json").write_text("")
    # Will match xray/configs/05_inbounds_h2*.json*
    (tmp_path / "xray" / "configs" / "05_inbounds_h2_x.json").write_text("")
    # Won't match anything in STALE_CONFIG_GLOBS
    (tmp_path / "xray" / "configs" / "keep_me.txt").write_text("")
    monkeypatch.setattr(mu, "PROJECT_ROOT", str(tmp_path))
    mu._wipe_stale_configs()
    assert not (tmp_path / "xray" / "configs" / "stale.json").exists()
    assert not (tmp_path / "xray" / "configs" / "05_inbounds_h2_x.json").exists()
    assert (tmp_path / "xray" / "configs" / "keep_me.txt").exists()


# ---- _merge_into_project --------------------------------------------------

def test_merge_overlays_staging_onto_project(tmp_path, monkeypatch):
    project = tmp_path / "project"
    staging = tmp_path / "staging"
    (project / "kept").mkdir(parents=True)
    (project / "kept" / "existing.txt").write_text("OLD")
    (project / "untouched.txt").write_text("STAYS")
    (staging / "kept").mkdir(parents=True)
    (staging / "kept" / "existing.txt").write_text("NEW")
    (staging / "new_dir" / "nested").mkdir(parents=True)
    (staging / "new_dir" / "nested" / "f.txt").write_text("FRESH")
    monkeypatch.setattr(mu, "PROJECT_ROOT", str(project))
    mu._merge_into_project(str(staging))
    assert (project / "kept" / "existing.txt").read_text() == "NEW"   # overwritten
    assert (project / "untouched.txt").read_text() == "STAYS"          # preserved
    assert (project / "new_dir" / "nested" / "f.txt").read_text() == "FRESH"


# ---- update_manager_source end-to-end --------------------------------------

def test_update_manager_source_unknown_mode_returns_false(tmp_path):
    with patch.object(mu, "log"):
        assert mu.update_manager_source("docker") is False
        assert mu.update_manager_source("mystery") is False


def test_update_manager_source_happy_path(tmp_path, monkeypatch):
    """Stub the download to point at a local zip, run the full flow."""
    project = tmp_path / "project"
    project.mkdir()
    monkeypatch.setattr(mu, "PROJECT_ROOT", str(project))

    archive_src = tmp_path / "fake.zip"
    with zipfile.ZipFile(archive_src, "w") as zf:
        zf.writestr("VERSION", "old")
        zf.writestr("README.md", "fresh contents")

    def fake_download(url, dest):
        import shutil
        shutil.copy(archive_src, dest)
    monkeypatch.setattr(mu, "_download", fake_download)

    assert mu.update_manager_source("release", override_version="42.0") is True
    # Override version was written
    assert (project / "VERSION").read_text() == "42.0\n"
    # Archive content landed
    assert (project / "README.md").read_text() == "fresh contents"
