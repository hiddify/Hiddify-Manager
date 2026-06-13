"""Tests for the pure helpers in hiddify_manager.modules.warp."""
import os

from hiddify_manager.modules import warp


PROFILE_V6 = """[Interface]
PrivateKey = abc
Address = 172.16.0.2/32
Address = 2606:4700:110:8000::1234/128
DNS = 1.1.1.1
[Peer]
PublicKey = xyz
"""


def test_patch_profile_strips_v6_when_ipv6_unusable(tmp_path):
    p = tmp_path / warp.PROFILE
    p.write_text(PROFILE_V6)
    assert warp._patch_profile(str(tmp_path), ipv6_ok=False)
    out = p.read_text()
    # v4 address untouched
    assert "Address = 172.16.0.2/32" in out
    # v6 address commented out
    assert "# Address = 2606:4700:110:8000::1234/128" in out
    # DNS commented
    assert "# DNS = 1.1.1.1" in out
    # Table = off inserted before [Peer]
    assert "Table = off\n[Peer]" in out


def test_patch_profile_keeps_v6_when_ipv6_usable(tmp_path):
    p = tmp_path / warp.PROFILE
    p.write_text(PROFILE_V6)
    assert warp._patch_profile(str(tmp_path), ipv6_ok=True)
    out = p.read_text()
    # v6 left intact
    assert "Address = 2606:4700:110:8000::1234/128" in out
    assert "# Address = 2606:4700:110:8000::1234/128" not in out
    # Table = off still inserted (independent of v6)
    assert "Table = off\n[Peer]" in out


def test_patch_profile_missing_file(tmp_path):
    assert warp._patch_profile(str(tmp_path), ipv6_ok=True) is False
