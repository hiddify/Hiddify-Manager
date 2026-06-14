"""
Progress markers for the panel's result.html live-tail.

The panel's JS parses each line of the action log for the marker

    ####<percent>####<title>####<subtitle>####

(regex `/####(?<progress>\\d+)####(?<title>.*?)####(?<subtitle>.*?)####/`)
and uses it to drive the progress bar + "title / details" labels.

Legacy bash printed these via `update_progress` in common/utils.sh:

    function update_progress() {
        title="${1^}"; text="$2"; percentage="$3"
        echo -e "####$percentage####$title####$text####"
    }

Same shape here.
"""


def progress(percent, title, subtitle=""):
    """Emit one progress marker. flush=True so each marker reaches the log
    file (which the panel polls every second) immediately, even if Python
    stdout is otherwise line-buffered."""
    # Match the legacy `${1^}` capitalize-first-letter behaviour so the
    # title in the UI looks the same as it used to.
    if title:
        title = title[:1].upper() + title[1:]
    print(f"####{percent}####{title}####{subtitle}####", flush=True)
