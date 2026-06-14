"""Tests for the pure helpers in modules.logs."""
import os
import time

from hiddify_manager.modules import logs


def test_fmt_size_handles_units():
    assert logs._fmt_size(0).strip() == "0B"
    assert logs._fmt_size(512).strip() == "512B"
    assert logs._fmt_size(2048).strip() == "2K"
    assert logs._fmt_size(5 * 1024 * 1024).strip() == "5M"
    assert logs._fmt_size(3 * 1024 ** 3).strip() == "3G"


def test_fmt_age_buckets():
    now = time.time()
    assert logs._fmt_age(now).endswith("s ago")
    assert logs._fmt_age(now - 90).endswith("m ago")
    assert logs._fmt_age(now - 7200).endswith("h ago")
    assert logs._fmt_age(now - 3 * 86400).endswith("d ago")


def test_list_logs_lists_only_regular_files(tmp_path, monkeypatch):
    monkeypatch.setattr(logs, "LOG_DIR", str(tmp_path))
    (tmp_path / "a.log").write_text("one\n")
    (tmp_path / "b.log").write_text("two\n")
    (tmp_path / "subdir").mkdir()
    out = logs._list_logs()
    names = [os.path.basename(p) for (p, _, _) in out]
    assert "a.log" in names
    assert "b.log" in names
    assert "subdir" not in names


def test_list_logs_returns_empty_when_dir_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(logs, "LOG_DIR", str(tmp_path / "nope"))
    assert logs._list_logs() == []


def test_tail_returns_last_n_lines(tmp_path):
    p = tmp_path / "x.log"
    p.write_text("\n".join(f"line{i}" for i in range(500)) + "\n")
    body = logs._tail(str(p), lines=10)
    last_lines = body.strip().splitlines()
    assert len(last_lines) == 10
    assert last_lines[-1] == "line499"


def test_tail_handles_missing_file(tmp_path):
    body = logs._tail(str(tmp_path / "absent"))
    assert "could not read" in body
