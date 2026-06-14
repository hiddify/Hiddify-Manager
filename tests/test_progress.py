"""Tests for the progress-marker emitter."""
import io
import re
from unittest.mock import patch

from hiddify_manager.utils.progress import progress


# The exact regex the panel's result.html JS uses to parse markers.
PANEL_REGEX = re.compile(r"####(?P<progress>\d+)####(?P<title>.*?)####(?P<subtitle>.*?)####")


def _capture(fn, *args, **kw):
    buf = io.StringIO()
    with patch("sys.stdout", buf):
        fn(*args, **kw)
    return buf.getvalue()


def test_format_matches_panel_regex():
    out = _capture(progress, 42, "Installing", "Nginx")
    match = PANEL_REGEX.search(out)
    assert match is not None, f"output {out!r} didn't match the panel regex"
    assert match.group("progress") == "42"
    assert match.group("title") == "Installing"
    assert match.group("subtitle") == "Nginx"


def test_capitalises_first_letter_of_title():
    """Legacy `${1^}` syntax uppercased the first letter; we match it."""
    out = _capture(progress, 10, "configuring", "system")
    match = PANEL_REGEX.search(out)
    assert match.group("title") == "Configuring"


def test_empty_subtitle_still_matches():
    out = _capture(progress, 100, "Done", "")
    match = PANEL_REGEX.search(out)
    assert match.group("subtitle") == ""


def test_trailing_newline_present():
    """print() adds the newline so each marker is on its own line."""
    out = _capture(progress, 50, "Halfway", "Hello")
    assert out.endswith("\n")


def test_marker_is_single_line():
    """The regex uses .*? non-greedy, but multi-line titles would break
    the panel's matching. Defensive: stay on one line."""
    out = _capture(progress, 50, "Halfway", "Hello")
    assert out.count("\n") == 1
