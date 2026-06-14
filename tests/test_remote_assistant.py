"""Tests for modules.remote_assistant."""
import os
from types import SimpleNamespace
from unittest.mock import patch

from hiddify_manager.modules import remote_assistant as ra


def test_add_creates_authorized_keys(tmp_path):
    with patch.object(ra, "_authorized_keys_path", return_value=str(tmp_path / "authorized_keys")), \
         patch.object(ra, "run_cmd", return_value=SimpleNamespace(returncode=0, stdout="")):
        ra.add()
    body = (tmp_path / "authorized_keys").read_text()
    assert ra.HIDDIFY_ASSISTANT_KEY in body
    assert oct((tmp_path / "authorized_keys").stat().st_mode)[-3:] == "600"


def test_add_does_not_dupe(tmp_path):
    auth = tmp_path / "authorized_keys"
    auth.write_text(ra.HIDDIFY_ASSISTANT_KEY + "\n")
    with patch.object(ra, "_authorized_keys_path", return_value=str(auth)), \
         patch.object(ra, "run_cmd", return_value=SimpleNamespace(returncode=0, stdout="")):
        ra.add()
    # Key should appear exactly once.
    assert auth.read_text().count(ra.HIDDIFY_ASSISTANT_KEY) == 1


def test_add_appends_to_existing_keys(tmp_path):
    auth = tmp_path / "authorized_keys"
    auth.write_text("ssh-rsa MINE my-key\n")
    with patch.object(ra, "_authorized_keys_path", return_value=str(auth)), \
         patch.object(ra, "run_cmd", return_value=SimpleNamespace(returncode=0, stdout="")):
        ra.add()
    body = auth.read_text()
    assert "ssh-rsa MINE my-key" in body  # existing key preserved
    assert ra.HIDDIFY_ASSISTANT_KEY in body


def test_remove_strips_only_assistant_line(tmp_path):
    auth = tmp_path / "authorized_keys"
    auth.write_text(
        "ssh-rsa OTHER_KEY user@host\n"
        + ra.HIDDIFY_ASSISTANT_KEY + "\n"
        + "ssh-rsa ANOTHER_KEY person@host\n"
    )
    with patch.object(ra, "_authorized_keys_path", return_value=str(auth)):
        ra.remove()
    body = auth.read_text()
    assert ra.HIDDIFY_ASSISTANT_KEY not in body
    assert "OTHER_KEY user@host" in body
    assert "ANOTHER_KEY person@host" in body


def test_remove_tolerates_missing_file(tmp_path):
    auth = tmp_path / "absent"
    with patch.object(ra, "_authorized_keys_path", return_value=str(auth)):
        ra.remove()  # should not raise


def test_ssh_port_parses_ss_output():
    output = (
        "Netid Recv-Q Send-Q Local Address:Port Peer Address:Port Process\n"
        "tcp   LISTEN 0 128 0.0.0.0:2200 0.0.0.0:* users:((\"sshd\",pid=1,fd=3))\n"
    )
    with patch.object(ra, "run_cmd", return_value=SimpleNamespace(returncode=0, stdout=output)):
        assert ra._ssh_listening_port() == 2200


def test_ssh_port_returns_none_when_sshd_missing():
    output = "tcp LISTEN 0 128 0.0.0.0:80 0.0.0.0:* users:((\"nginx\",pid=1,fd=3))\n"
    with patch.object(ra, "run_cmd", return_value=SimpleNamespace(returncode=0, stdout=output)):
        assert ra._ssh_listening_port() is None
