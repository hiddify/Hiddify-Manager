"""Tests for utils/firewall.py.

We mock run_cmd so the tests don't poke real iptables. The goal is to
verify the argv shape (the rules we hand to iptables) and the idempotent
-C/-I dance, not to second-guess iptables itself.
"""
from types import SimpleNamespace
from unittest.mock import patch, call

from hiddify_manager.utils import firewall as fw


def _result(returncode=0, stdout=""):
    return SimpleNamespace(returncode=returncode, stdout=stdout)


def test_add_rule_skips_when_already_present():
    """If -C returns 0 (rule exists), -I should NOT be invoked."""
    calls = []
    def fake(argv, **kw):
        calls.append((argv, kw))
        # -C returns 0 -> already exists
        return _result(0)
    with patch.object(fw, "run_cmd", side_effect=fake):
        fw.add_rule(["INPUT", "-p", "tcp", "--dport", "443", "-j", "ACCEPT"])
    # Two -C checks (v4 + v6), zero -I.
    assert [c[0][:2] for c in calls] == [["iptables", "-C"], ["ip6tables", "-C"]]


def test_add_rule_inserts_when_missing():
    """If -C returns non-zero, -I should be invoked with the same argv."""
    def fake(argv, **kw):
        return _result(1 if argv[1] == "-C" else 0)
    with patch.object(fw, "run_cmd", side_effect=fake) as m:
        fw.add_rule(["INPUT", "-p", "udp", "--dport", "443", "-j", "ACCEPT"])
    actions = [c.args[0][:2] for c in m.call_args_list]
    assert actions == [
        ["iptables", "-C"], ["iptables", "-I"],
        ["ip6tables", "-C"], ["ip6tables", "-I"],
    ]


def test_add_rule_both_false_skips_v6():
    def fake(argv, **kw):
        return _result(1)
    with patch.object(fw, "run_cmd", side_effect=fake) as m:
        fw.add_rule(["INPUT", "-p", "icmp", "-j", "ACCEPT"], both=False)
    binaries = {c.args[0][0] for c in m.call_args_list}
    assert binaries == {"iptables"}


def test_allow_port_emits_dport_and_conntrack_rules():
    """allow_port should produce both the simple --dport rule and the
    conntrack NEW rule, on both v4 and v6 — matching legacy allow_port."""
    inserted = []
    def fake(argv, **kw):
        if argv[1] == "-C":
            return _result(1)  # always 'missing' -> trigger -I
        if argv[1] == "-I":
            inserted.append(argv)
        return _result(0)
    with patch.object(fw, "run_cmd", side_effect=fake):
        fw.allow_port("tcp", 8443)
    # 2 rules x 2 binaries = 4 inserts
    assert len(inserted) == 4
    # Spot-check: one of them is the conntrack NEW rule
    assert any("conntrack" in argv and "--ctstate" in argv for argv in inserted)
    assert any("--dport" in argv and "8443" in argv for argv in inserted)


def test_remove_port_calls_delete_on_both_families():
    with patch.object(fw, "run_cmd") as m:
        fw.remove_port("tcp", 80)
    binaries = [c.args[0][0] for c in m.call_args_list]
    actions = [c.args[0][1] for c in m.call_args_list]
    assert binaries == ["iptables", "ip6tables"]
    assert actions == ["-D", "-D"]


def test_set_input_policy_accept_applies_to_input_and_forward_v4v6():
    with patch.object(fw, "run_cmd") as m:
        fw.set_input_policy("ACCEPT")
    invocations = [c.args[0] for c in m.call_args_list]
    # 2 binaries x 2 chains = 4 -P invocations
    assert len(invocations) == 4
    assert {tuple(a[:1] + a[2:]) for a in invocations} == {
        ("iptables", "INPUT", "ACCEPT"),
        ("iptables", "FORWARD", "ACCEPT"),
        ("ip6tables", "INPUT", "ACCEPT"),
        ("ip6tables", "FORWARD", "ACCEPT"),
    }


def test_set_input_policy_refuses_invalid_value():
    with patch.object(fw, "run_cmd") as m, patch.object(fw, "log") as mlog:
        fw.set_input_policy("MAYBE")
    m.assert_not_called()
    mlog.error.assert_called()


def test_save_dedupes_and_restores(tmp_path):
    """save() should dump, dedupe ONLY rule lines, preserve structural
    lines (incl. the dump's own COMMIT), write to /etc/iptables/rules.vX,
    and feed the result back through *-restore."""
    dumps = {
        "iptables-save": "*filter\n:INPUT ACCEPT [0:0]\n-A INPUT -j ACCEPT\n-A INPUT -j ACCEPT\nCOMMIT\n",
        "ip6tables-save": "*filter\n:INPUT ACCEPT [0:0]\nCOMMIT\n",
    }
    restore_inputs = {}
    def fake(argv, **kw):
        binname = argv[0]
        if binname in dumps:
            return _result(0, dumps[binname])
        if binname in ("iptables-restore", "ip6tables-restore"):
            restore_inputs[binname] = kw.get("input_data", "")
            return _result(0)
        return _result(0)

    with patch.object(fw, "run_cmd", side_effect=fake), \
         patch("os.makedirs"), \
         patch("builtins.open") as mock_open:
        # Patch open to capture writes + reads
        written = {}
        def open_side(path, mode="r", **kw):
            if "w" in mode:
                from io import StringIO
                buf = StringIO()
                buf.close_orig = buf.close
                def close():
                    written[path] = buf.getvalue()
                    buf.close_orig()
                buf.close = close
                return buf
            from io import StringIO
            return StringIO(written.get(path, ""))
        mock_open.side_effect = open_side
        fw.save()

    # v4 dump had a duplicate '-A INPUT -j ACCEPT'; expect it kept only once.
    assert written["/etc/iptables/rules.v4"].count("-A INPUT -j ACCEPT\n") == 1
    # Structural lines preserved verbatim, exactly one COMMIT (the dump's),
    # NOT a second appended one (the old bug).
    assert written["/etc/iptables/rules.v4"].count("COMMIT\n") == 1
    assert written["/etc/iptables/rules.v6"].count("COMMIT\n") == 1
    assert "*filter\n" in written["/etc/iptables/rules.v4"]
    assert ":INPUT ACCEPT [0:0]\n" in written["/etc/iptables/rules.v4"]
    # restore was invoked with the cleaned content
    assert "iptables-restore" in restore_inputs
    assert "-A INPUT -j ACCEPT" in restore_inputs["iptables-restore"]


def test_save_dedups_rules_per_table_not_across(tmp_path):
    """A rule line identical across two tables must survive in both —
    dedup resets at each '*table' boundary."""
    dump = (
        "*filter\n:INPUT ACCEPT [0:0]\n-A INPUT -j ACCEPT\nCOMMIT\n"
        "*nat\n:PREROUTING ACCEPT [0:0]\n-A INPUT -j ACCEPT\nCOMMIT\n"
    )
    written = {}
    def fake(argv, **kw):
        if argv[0] == "iptables-save":
            return _result(0, dump)
        return _result(0)
    with patch.object(fw, "run_cmd", side_effect=fake), \
         patch("os.makedirs"), \
         patch("builtins.open") as mock_open:
        def open_side(path, mode="r", **kw):
            from io import StringIO
            if "w" in mode:
                buf = StringIO(); orig = buf.close
                buf.close = lambda: (written.__setitem__(path, buf.getvalue()), orig())
                return buf
            return StringIO(written.get(path, ""))
        mock_open.side_effect = open_side
        # Only exercise the v4 path by making v6 dump empty/fail.
        fw.save()
    v4 = written["/etc/iptables/rules.v4"]
    # The identical -A line appears once per table = twice total.
    assert v4.count("-A INPUT -j ACCEPT\n") == 2
    assert v4.count("*filter\n") == 1 and v4.count("*nat\n") == 1
