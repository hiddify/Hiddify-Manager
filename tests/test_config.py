import json
from unittest.mock import patch

import pytest

from hiddify_manager.utils import config as cfg


SAMPLE = {
    "chconfigs": {
        "0": {"warp_plus_code": "XYZ", "wireguard_port": 51820},
        "1": {"warp_plus_code": "other"},
    }
}


def _write_current(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text(json.dumps(SAMPLE))
    return str(cj)


def test_hconfig_reads_chconfigs_zero(tmp_path):
    cj = _write_current(tmp_path)
    with patch.object(cfg, "CURRENT_JSON", cj):
        assert cfg.hconfig("warp_plus_code") == "XYZ"
        assert cfg.hconfig("wireguard_port") == 51820


def test_hconfig_missing_key_returns_none(tmp_path):
    cj = _write_current(tmp_path)
    with patch.object(cfg, "CURRENT_JSON", cj):
        assert cfg.hconfig("nope") is None


def test_load_configs_corrupted(tmp_path):
    cj = tmp_path / "current.json"
    cj.write_text("{not json")
    with patch.object(cfg, "CURRENT_JSON", str(cj)):
        assert cfg.load_configs() is None


def test_load_configs_triggers_generation_when_missing(tmp_path):
    cj = str(tmp_path / "current.json")
    with patch.object(cfg, "CURRENT_JSON", cj), \
         patch.object(cfg, "generate_current_json", return_value=False) as gen:
        assert cfg.load_configs() is None
        gen.assert_called_once()
