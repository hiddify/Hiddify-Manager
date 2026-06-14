"""Tests for the pure helpers in hiddify_manager.modules.warp."""
import os

from hiddify_manager.modules import warp


PROFILE_CURRENT_WGCF = """[Interface]
PrivateKey = abc
Address = 172.16.0.2/32, 2606:4700:110:80b4::1234/128
DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001
MTU = 1280
[Peer]
PublicKey = xyz
"""


def test_patch_profile_keeps_v4_when_v6_unusable(tmp_path):
    """
    Regression test: wgcf now emits comma-separated v4+v6 on a single
    Address line. We must keep the v4 even when v6 is disabled, otherwise
    the interface comes up with no address and routes break.
    """
    p = tmp_path / warp.PROFILE
    p.write_text(PROFILE_CURRENT_WGCF)
    assert warp._patch_profile(str(tmp_path), ipv6_ok=False)
    out = p.read_text()
    # v4 retained
    assert "Address = 172.16.0.2/32\n" in out
    # original v6 entry gone
    assert "2606:4700:110:80b4::1234" not in out
    # DNS line commented (Cloudflare push removed regardless of v6)
    assert "# DNS = " in out
    # Table = off inserted before [Peer]
    assert "Table = off\n[Peer]" in out


def test_patch_profile_keeps_v6_when_v6_usable(tmp_path):
    p = tmp_path / warp.PROFILE
    p.write_text(PROFILE_CURRENT_WGCF)
    assert warp._patch_profile(str(tmp_path), ipv6_ok=True)
    out = p.read_text()
    # v6 retained verbatim
    assert "2606:4700:110:80b4::1234" in out
    # v4 too
    assert "172.16.0.2/32" in out
    # DNS line still gets commented (Cloudflare DNS push policy)
    assert "# DNS = " in out


def test_strip_v6_from_csv_v6_only_comments(tmp_path):
    """If the address list is only v6 entries, comment the whole line."""
    out = warp._strip_v6_from_csv(
        "Address = ", "Address = 2606:4700:110::1/128\n", ipv6_ok=False
    )
    assert out == "# Address = 2606:4700:110::1/128\n"


def test_strip_v6_from_csv_noop_when_ipv6_ok():
    raw = "Address = 172.16.0.2/32, 2606:4700:110::1/128\n"
    assert warp._strip_v6_from_csv("Address = ", raw, ipv6_ok=True) == raw


def test_patch_profile_missing_file(tmp_path):
    assert warp._patch_profile(str(tmp_path), ipv6_ok=True) is False
